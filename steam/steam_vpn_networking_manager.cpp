#include "steam_vpn_networking_manager.h"
#include "steam_vpn_bridge.h"
#include "vpn_message_handler.h"
#include "../net/vpn_protocol.h"

#include <algorithm>
#include <chrono>
#include <cstring>
#include <iostream>
#include <steam_api.h>
#include <isteamnetworkingutils.h>

namespace {
int compareVersion(const std::string &a, const std::string &b) {
  size_t i = 0;
  size_t j = 0;
  while (i < a.size() || j < b.size()) {
    int x = 0;
    int y = 0;
    while (i < a.size() && a[i] != '.') {
      if (a[i] >= '0' && a[i] <= '9') {
        x = x * 10 + (a[i] - '0');
      }
      ++i;
    }
    while (j < b.size() && b[j] != '.') {
      if (b[j] >= '0' && b[j] <= '9') {
        y = y * 10 + (b[j] - '0');
      }
      ++j;
    }
    if (x < y) {
      return -1;
    }
    if (x > y) {
      return 1;
    }
    if (i < a.size()) {
      ++i;
    }
    if (j < b.size()) {
      ++j;
    }
  }
  return 0;
}

long long unixTimeSeconds() {
  using namespace std::chrono;
  return duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
}
} // namespace

SteamVpnNetworkingManager::SteamVpnNetworkingManager()
    : messagesInterface_(nullptr), messageHandler_(nullptr),
      vpnBridge_(nullptr) {}

SteamVpnNetworkingManager::~SteamVpnNetworkingManager() {
  stopMessageHandler();
  delete messageHandler_;
  shutdown();
}

bool SteamVpnNetworkingManager::initialize() {
  if (!SteamAPI_IsSteamRunning()) {
    std::cerr << "Steam is not running" << std::endl;
    return false;
  }

  int32 sendBufferSize = 4 * 1024 * 1024;
  SteamNetworkingUtils()->SetConfigValue(
      k_ESteamNetworkingConfig_SendBufferSize, k_ESteamNetworkingConfig_Global,
      0, k_ESteamNetworkingConfig_Int32, &sendBufferSize);

  int32 recvBufferSize = 4 * 1024 * 1024;
  SteamNetworkingUtils()->SetConfigValue(
      k_ESteamNetworkingConfig_RecvBufferSize, k_ESteamNetworkingConfig_Global,
      0, k_ESteamNetworkingConfig_Int32, &recvBufferSize);
  int32 recvBufferMsgs = 2048;
  SteamNetworkingUtils()->SetConfigValue(
      k_ESteamNetworkingConfig_RecvBufferMessages,
      k_ESteamNetworkingConfig_Global, 0, k_ESteamNetworkingConfig_Int32,
      &recvBufferMsgs);
  int32 sendRate = 4 * 1024 * 1024;
  SteamNetworkingUtils()->SetConfigValue(
      k_ESteamNetworkingConfig_SendRateMin, k_ESteamNetworkingConfig_Global, 0,
      k_ESteamNetworkingConfig_Int32, &sendRate);
  SteamNetworkingUtils()->SetConfigValue(
      k_ESteamNetworkingConfig_SendRateMax, k_ESteamNetworkingConfig_Global, 0,
      k_ESteamNetworkingConfig_Int32, &sendRate);

  int32 nagleTime = 0;
  SteamNetworkingUtils()->SetConfigValue(
      k_ESteamNetworkingConfig_NagleTime, k_ESteamNetworkingConfig_Global, 0,
      k_ESteamNetworkingConfig_Int32, &nagleTime);

  int32 nIceEnable = k_nSteamNetworkingConfig_P2P_Transport_ICE_Enable_Public |
                     k_nSteamNetworkingConfig_P2P_Transport_ICE_Enable_Private;
  SteamNetworkingUtils()->SetConfigValue(
      k_ESteamNetworkingConfig_P2P_Transport_ICE_Enable,
      k_ESteamNetworkingConfig_Global, 0, k_ESteamNetworkingConfig_Int32,
      &nIceEnable);

  int32 sdrPenalty = 0;
  SteamNetworkingUtils()->SetConfigValue(
      k_ESteamNetworkingConfig_P2P_Transport_SDR_Penalty,
      k_ESteamNetworkingConfig_Global, 0, k_ESteamNetworkingConfig_Int32,
      &sdrPenalty);

  SteamNetworkingUtils()->InitRelayNetworkAccess();

  messagesInterface_ = SteamNetworkingMessages();
  if (!messagesInterface_) {
    std::cerr << "Failed to get ISteamNetworkingMessages interface"
              << std::endl;
    return false;
  }

  messageHandler_ = new VpnMessageHandler(messagesInterface_, this);
  return true;
}

void SteamVpnNetworkingManager::shutdown() {
  {
    std::lock_guard<std::mutex> lock(peersMutex_);
    for (const auto &peer : peers_) {
      SteamNetworkingIdentity identity;
      identity.SetSteamID(peer);
      if (messagesInterface_) {
        messagesInterface_->CloseSessionWithUser(identity);
      }
    }
    peers_.clear();
  }
  hostSteamID_ = CSteamID();
}

bool SteamVpnNetworkingManager::sendMessageToUser(CSteamID peerID,
                                                  const void *data,
                                                  uint32_t size, int flags) {
  if (!messagesInterface_) {
    return false;
  }
  SteamNetworkingIdentity identity;
  identity.SetSteamID(peerID);
  const EResult result = messagesInterface_->SendMessageToUser(
      identity, data, size, flags, VPN_CHANNEL);
  return result == k_EResultOK;
}

void SteamVpnNetworkingManager::broadcastMessage(const void *data,
                                                 uint32_t size, int flags) {
  if (!messagesInterface_) {
    return;
  }
  std::lock_guard<std::mutex> lock(peersMutex_);
  for (const auto &peerID : peers_) {
    SteamNetworkingIdentity identity;
    identity.SetSteamID(peerID);
    messagesInterface_->SendMessageToUser(identity, data, size, flags,
                                          VPN_CHANNEL);
  }
}

void SteamVpnNetworkingManager::addPeer(CSteamID peerID) {
  if (!messagesInterface_) {
    return;
  }
  if (SteamUser() && peerID == SteamUser()->GetSteamID()) {
    return;
  }
  bool isNew = false;
  {
    std::lock_guard<std::mutex> lock(peersMutex_);
    isNew = peers_.insert(peerID).second;
  }
  // Force a fresh session even if we already know this peer, so reconnects
  // after a leave/rejoin can renegotiate cleanly.
  SteamNetworkingIdentity identity;
  identity.SetSteamID(peerID);
  messagesInterface_->CloseSessionWithUser(identity);
  messagesInterface_->AcceptSessionWithUser(identity);
  VpnMessageHeader hello{};
  hello.type = VpnMessageType::SESSION_HELLO;
  SessionHelloPayload payload{};
  std::memset(&payload, 0, sizeof(payload));
  if (!localVersion_.empty()) {
    const size_t maxLen = VPN_VERSION_MAX_LEN - 1;
    const size_t copyLen = std::min(localVersion_.size(), maxLen);
    std::memcpy(payload.version, localVersion_.data(), copyLen);
    payload.version[copyLen] = '\0';
  }
  payload.capabilities = 0;
  payload.capabilities |= VPN_CAP_PASSWORD;
  hello.length = htons(static_cast<uint16_t>(sizeof(SessionHelloPayload)));
  uint8_t buffer[sizeof(VpnMessageHeader) + sizeof(SessionHelloPayload)];
  std::memcpy(buffer, &hello, sizeof(VpnMessageHeader));
  std::memcpy(buffer + sizeof(VpnMessageHeader), &payload,
              sizeof(SessionHelloPayload));
  const int flags = k_nSteamNetworkingSend_Reliable |
                    k_nSteamNetworkingSend_AutoRestartBrokenSession;
  const EResult result = messagesInterface_->SendMessageToUser(
      identity, buffer, sizeof(buffer), flags, VPN_CHANNEL);
  if (result == k_EResultOK) {
    std::cout << "[SteamVPN] Sent SESSION_HELLO to "
              << peerID.ConvertToUint64() << std::endl;
  } else {
    std::cout << "[SteamVPN] Failed to send SESSION_HELLO to "
              << peerID.ConvertToUint64() << ", result: " << result
              << std::endl;
  }
  if (vpnBridge_) {
    vpnBridge_->onUserJoined(peerID);
  }
}

void SteamVpnNetworkingManager::removePeer(CSteamID peerID) {
  bool removed = false;
  {
    std::lock_guard<std::mutex> lock(peersMutex_);
    removed = peers_.erase(peerID) > 0;
  }
  if (removed) {
    SteamNetworkingIdentity identity;
    identity.SetSteamID(peerID);
    if (messagesInterface_) {
      messagesInterface_->CloseSessionWithUser(identity);
    }
    if (vpnBridge_) {
      vpnBridge_->onUserLeft(peerID);
    }
  }
}

void SteamVpnNetworkingManager::clearPeers() {
  std::lock_guard<std::mutex> lock(peersMutex_);
  for (const auto &peerID : peers_) {
    SteamNetworkingIdentity identity;
    identity.SetSteamID(peerID);
    if (messagesInterface_) {
      messagesInterface_->CloseSessionWithUser(identity);
    }
    if (vpnBridge_) {
      vpnBridge_->onUserLeft(peerID);
    }
  }
  peers_.clear();
}

void SteamVpnNetworkingManager::syncPeers(
    const std::set<CSteamID> &desiredPeers) {
  std::set<CSteamID> current;
  {
    std::lock_guard<std::mutex> lock(peersMutex_);
    current = peers_;
  }
  for (const auto &peer : desiredPeers) {
    if (current.find(peer) == current.end()) {
      addPeer(peer);
    }
  }
  for (const auto &peer : current) {
    if (desiredPeers.find(peer) == desiredPeers.end()) {
      removePeer(peer);
    }
  }
}

std::set<CSteamID> SteamVpnNetworkingManager::getPeers() const {
  std::lock_guard<std::mutex> lock(peersMutex_);
  return peers_;
}

int SteamVpnNetworkingManager::getPeerPing(CSteamID peerID) const {
  if (!messagesInterface_) {
    return -1;
  }
  SteamNetworkingIdentity identity;
  identity.SetSteamID(peerID);
  SteamNetConnectionRealTimeStatus_t status;
  const ESteamNetworkingConnectionState state =
      messagesInterface_->GetSessionConnectionInfo(identity, nullptr, &status);
  if (state == k_ESteamNetworkingConnectionState_Connected) {
    return status.m_nPing;
  }
  return -1;
}

bool SteamVpnNetworkingManager::isPeerConnected(CSteamID peerID) const {
  if (!messagesInterface_) {
    return false;
  }
  SteamNetworkingIdentity identity;
  identity.SetSteamID(peerID);
  const ESteamNetworkingConnectionState state =
      messagesInterface_->GetSessionConnectionInfo(identity, nullptr, nullptr);
  return state == k_ESteamNetworkingConnectionState_Connected;
}

std::string
SteamVpnNetworkingManager::getPeerConnectionType(CSteamID peerID) const {
  if (!messagesInterface_) {
    return "N/A";
  }
  SteamNetworkingIdentity identity;
  identity.SetSteamID(peerID);
  SteamNetConnectionInfo_t info;
  const ESteamNetworkingConnectionState state =
      messagesInterface_->GetSessionConnectionInfo(identity, &info, nullptr);
  if (state == k_ESteamNetworkingConnectionState_Connected) {
    if (info.m_nFlags & k_nSteamNetworkConnectionInfoFlags_Relayed) {
      return "中继";
    }
    return "直连";
  }
  return "N/A";
}

void SteamVpnNetworkingManager::startMessageHandler() {
  if (messageHandler_) {
    messageHandler_->start();
  }
}

void SteamVpnNetworkingManager::stopMessageHandler() {
  if (messageHandler_) {
    messageHandler_->stop();
  }
}

void SteamVpnNetworkingManager::handleIncomingVpnMessage(
    const uint8_t *data, size_t size, CSteamID senderSteamID) {
  if (!vpnBridge_) {
    return;
  }
  vpnBridge_->handleVpnMessage(data, size, senderSteamID);
}

void SteamVpnNetworkingManager::handleSessionHello(const uint8_t *data,
                                                   size_t size,
                                                   CSteamID senderSteamID) {
  if (size < sizeof(VpnMessageHeader)) {
    return;
  }
  VpnMessageHeader header{};
  std::memcpy(&header, data, sizeof(VpnMessageHeader));
  const uint16_t payloadLength = ntohs(header.length);
  const size_t available = size > sizeof(VpnMessageHeader)
                               ? size - sizeof(VpnMessageHeader)
                               : 0;
  std::string remoteVersion;
  uint8_t remoteCapabilities = 0;
  if (payloadLength >= sizeof(SessionHelloPayload) &&
      available >= sizeof(SessionHelloPayload)) {
    SessionHelloPayload payload{};
    std::memcpy(&payload, data + sizeof(VpnMessageHeader),
                sizeof(SessionHelloPayload));
    char versionBuf[VPN_VERSION_MAX_LEN + 1];
    std::memcpy(versionBuf, payload.version, VPN_VERSION_MAX_LEN);
    versionBuf[VPN_VERSION_MAX_LEN] = '\0';
    remoteVersion = std::string(versionBuf);
    while (!remoteVersion.empty() &&
           (remoteVersion.back() == '\0' || remoteVersion.back() == ' ')) {
      remoteVersion.pop_back();
    }
    remoteCapabilities = payload.capabilities;
  }

  bool blocked = false;
  const std::string minSupportedVersion = "0.8.0";
  if (!remoteVersion.empty() &&
      compareVersion(remoteVersion, minSupportedVersion) < 0) {
    blocked = true;
  }
  if (!blocked && passwordProtected_ &&
      (remoteCapabilities & VPN_CAP_PASSWORD) == 0) {
    blocked = true;
  }

  std::string remoteIp = "";
  if (messagesInterface_) {
    SteamNetworkingIdentity identity;
    identity.SetSteamID(senderSteamID);
    SteamNetConnectionInfo_t info;
    const ESteamNetworkingConnectionState state =
        messagesInterface_->GetSessionConnectionInfo(identity, &info, nullptr);
    if (state == k_ESteamNetworkingConnectionState_Connected) {
      char buf[64];
      info.m_addrRemote.ToString(buf, sizeof(buf), true);
      remoteIp = std::string(buf);
    }
  }

  const std::string versionForLog =
      remoteVersion.empty() ? std::string("unknown") : remoteVersion;

  if (blocked) {
    {
      std::lock_guard<std::mutex> lock(peersMutex_);
      peers_.erase(senderSteamID);
    }
    if (messagesInterface_) {
      SteamNetworkingIdentity identity;
      identity.SetSteamID(senderSteamID);
      messagesInterface_->CloseSessionWithUser(identity);
    }
    std::cout << "[SteamVPN] ts=" << unixTimeSeconds()
              << " blocked peer=" << senderSteamID.ConvertToUint64()
              << " ip=" << (remoteIp.empty() ? "N/A" : remoteIp)
              << " version=" << versionForLog << std::endl;
    if (clientBlockedCallback_) {
      clientBlockedCallback_(senderSteamID, versionForLog);
    }
    return;
  }

  std::cout << "[SteamVPN] ts=" << unixTimeSeconds()
            << " accepted peer=" << senderSteamID.ConvertToUint64()
            << " ip=" << (remoteIp.empty() ? "N/A" : remoteIp)
            << " version=" << versionForLog << std::endl;
}

void SteamVpnNetworkingManager::OnSessionRequest(
    SteamNetworkingMessagesSessionRequest_t *pCallback) {
  const CSteamID remoteSteamID = pCallback->m_identityRemote.GetSteamID();
  std::cout << "[SteamVPN] Session request from "
            << remoteSteamID.ConvertToUint64() << std::endl;
  bool accept = false;
  accept = true;
  if (messagesInterface_) {
    messagesInterface_->AcceptSessionWithUser(pCallback->m_identityRemote);
    std::cout << "[SteamVPN] Accepted session from known peer" << std::endl;
  }
}

void SteamVpnNetworkingManager::OnSessionFailed(
    SteamNetworkingMessagesSessionFailed_t *pCallback) {
  const CSteamID remoteSteamID = pCallback->m_info.m_identityRemote.GetSteamID();
  std::cout << "[SteamVPN] Session failed with "
            << remoteSteamID.ConvertToUint64() << ": "
            << pCallback->m_info.m_szEndDebug << std::endl;
  removePeer(remoteSteamID);
}
