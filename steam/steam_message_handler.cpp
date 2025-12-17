#include "steam_message_handler.h"
#include "steam_networking_manager.h"
#include "../net/udp_forwarder.h"
#include <chrono>
#include <cstring>
#include <iostream>
#include <isteamnetworkingsockets.h>
#include <steam_api.h>

SteamMessageHandler::SteamMessageHandler(
    boost::asio::io_context &io_context, ISteamNetworkingSockets *interface,
    std::vector<HSteamNetConnection> &connections, std::mutex &connectionsMutex,
    bool &g_isHost, int &localPort, SteamNetworkingManager *owner)
    : io_context_(io_context), m_pInterface_(interface),
      connections_(connections), connectionsMutex_(connectionsMutex),
      g_isHost_(g_isHost), localPort_(localPort), multiplexManagers_(),
      timer_(), running_(false), currentPollInterval_(0), owner_(owner) {}

SteamMessageHandler::~SteamMessageHandler() { stop(); }

void SteamMessageHandler::start() {
  if (running_)
    return;
  running_ = true;
  timer_ = std::make_unique<boost::asio::steady_timer>(io_context_);
  startAsyncPoll();
}

void SteamMessageHandler::stop() {
  if (!running_)
    return;
  running_ = false;
  if (timer_) {
    timer_->cancel();
  }
}

std::shared_ptr<MultiplexManager>
SteamMessageHandler::getMultiplexManager(HSteamNetConnection conn) {
  if (multiplexManagers_.find(conn) == multiplexManagers_.end()) {
    multiplexManagers_[conn] = std::make_shared<MultiplexManager>(
        m_pInterface_, conn, io_context_, g_isHost_, localPort_);
  }
  return multiplexManagers_[conn];
}

void SteamMessageHandler::startAsyncPoll() {
  if (!running_)
    return;

  // Poll networking callbacks
  m_pInterface_->RunCallbacks();

  // Receive messages and check if any were received
  int totalMessages = 0;
  std::vector<HSteamNetConnection> currentConnections;
  {
    std::lock_guard<std::mutex> lockConn(connectionsMutex_);
    currentConnections = connections_;
  }
  for (auto conn : currentConnections) {
    ISteamNetworkingMessage *pIncomingMsgs[256];
    int numMsgs =
        m_pInterface_->ReceiveMessagesOnConnection(conn, pIncomingMsgs, 256);
    totalMessages += numMsgs;
    for (int i = 0; i < numMsgs; ++i) {
      ISteamNetworkingMessage *pIncomingMsg = pIncomingMsgs[i];
      const char *data = (const char *)pIncomingMsg->m_pData;
      size_t size = pIncomingMsg->m_cbSize;
      if (size >= 1 && data[0] == '\x02') {
        handleUdpTunnelPacket(conn, data + 1, size - 1);
      } else {
        if (multiplexManagers_.find(conn) == multiplexManagers_.end()) {
          multiplexManagers_[conn] = std::make_shared<MultiplexManager>(
              m_pInterface_, conn, io_context_, g_isHost_, localPort_);
        }
        multiplexManagers_[conn]->handleTunnelPacket(data, size);
      }
      pIncomingMsg->Release();
    }
  }

  // Adaptive polling: if messages received, poll immediately; otherwise
  // increase interval (keep small to avoid backlog)
  if (totalMessages > 0) {
    currentPollInterval_ = 0; // 有消息，立即轮询
  } else {
    // 无消息，逐渐增加间隔，最大2ms，优先低延迟
    currentPollInterval_ = std::min(currentPollInterval_ + 1, 2);
  }

  // Schedule next poll
  timer_->expires_after(std::chrono::milliseconds(currentPollInterval_));
  timer_->async_wait([this](const boost::system::error_code &error) {
    if (!error && running_) {
      startAsyncPoll();
    }
  });
}

void SteamMessageHandler::handleUdpTunnelPacket(HSteamNetConnection conn,
                                                const char* data,
                                                size_t len) {
  if (!owner_) {
    return;
  }
  auto *forwarder = owner_->getUdpForwarder();
  if (!forwarder) {
    return;
  }
  forwarder->handleTunnelPacket(conn, data, len);
}
