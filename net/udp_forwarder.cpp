#include "udp_forwarder.h"

#include "../steam/steam_networking_manager.h"
#include <random>
#include <cstring>

namespace {
std::string generateUdpId() {
    static const char chars[] =
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    static thread_local std::mt19937 rng{std::random_device{}()};
    std::uniform_int_distribution<std::size_t> dist(0, sizeof(chars) - 2);
    std::string id;
    id.resize(6);
    for (std::size_t i = 0; i < id.size(); ++i) {
        id[i] = chars[dist(rng)];
    }
    return id;
}
} // namespace

struct UDPForwarder::TargetSession {
    explicit TargetSession(boost::asio::io_context& context) : socket(context) {}

    udp::socket socket;
    udp::endpoint remote;
    std::array<char, 65536> buffer{};
    bool receiving = false;
};

UDPForwarder::UDPForwarder(int bindPort,
                           int targetPort,
                           SteamNetworkingManager* manager)
    : bindPort_(bindPort),
      targetPort_(targetPort),
      running_(false),
      work_(boost::asio::make_work_guard(io_context_)),
      socket_(io_context_),
      manager_(manager) {}

UDPForwarder::~UDPForwarder() {
    stop();
}

bool UDPForwarder::start() {
    try {
        udp::endpoint endpoint(udp::v4(), bindPort_);
        socket_.open(endpoint.protocol());
        socket_.bind(endpoint);
        running_ = true;
        worker_ = std::thread([this]() { io_context_.run(); });
        if (bindPort_ > 0) {
            startReceive();
        }
        return true;
    } catch (const std::exception&) {
        return false;
    }
}

void UDPForwarder::stop() {
    running_ = false;
    io_context_.stop();
    if (worker_.joinable()) {
        worker_.join();
    }
    boost::system::error_code ec;
    socket_.close(ec);

    {
        std::lock_guard<std::mutex> lock(clientsMutex_);
        for (auto& pair : targetSessions_) {
            boost::system::error_code ignored;
            pair.second->socket.close(ignored);
        }
        targetSessions_.clear();
        idToConn_.clear();
    }
}

int UDPForwarder::getClientCount() {
    std::lock_guard<std::mutex> lock(clientsMutex_);
    return static_cast<int>(clientToId_.size());
}

void UDPForwarder::setClientCountCallback(std::function<void(int)> callback) {
    clientCountCallback_ = std::move(callback);
}

void UDPForwarder::notifyClientCount(int count) {
    if (clientCountCallback_) {
        clientCountCallback_(count);
    }
}

void UDPForwarder::startReceive() {
    socket_.async_receive_from(
        boost::asio::buffer(recvBuffer_), remoteEndpoint_,
        [this](const boost::system::error_code& ec, std::size_t bytes) {
            if (!ec && bytes > 0 && manager_) {
                ClientKey key{remoteEndpoint_};
                std::string id;
                bool added = false;
                {
                    std::lock_guard<std::mutex> lock(clientsMutex_);
                    auto it = clientToId_.find(key);
                    if (it == clientToId_.end()) {
                        id = generateUdpId();
                        clientToId_[key] = id;
                        idToClient_[id] = key;
                        added = true;
                    } else {
                        id = it->second;
                    }
                }
                if (added) {
                    notifyClientCount(static_cast<int>(clientToId_.size()));
                }
                sendTunnelPacket(id, recvBuffer_.data(), bytes);
            }
            if (running_) {
                startReceive();
            }
        });
}

void UDPForwarder::startTargetReceive(const std::string& id, const std::shared_ptr<TargetSession>& session) {
    if (!running_ || !session) {
        if (session) {
            session->receiving = false;
        }
        return;
    }
    session->socket.async_receive_from(
        boost::asio::buffer(session->buffer), session->remote,
        [this, id, session](const boost::system::error_code& ec, std::size_t bytes) {
            if (ec || !running_) {
                session->receiving = false;
                return;
            }
            if (bytes > 0) {
                sendTunnelPacket(id, session->buffer.data(), bytes);
            }
            startTargetReceive(id, session);
        });
}

void UDPForwarder::sendTunnelPacket(const std::string& id,
                                    const char* data,
                                    size_t len) {
    if (!manager_ || !manager_->isConnected()) {
        return;
    }
    ISteamNetworkingSockets* interfacePtr = manager_->getInterface();
    if (!interfacePtr) {
        return;
    }

    std::vector<char> packet;
    packet.reserve(1 + 6 + len);
    packet.push_back('\x02');

    char idBuf[6] = {};
    if (!id.empty()) {
        const std::size_t copyLen = std::min<std::size_t>(6, id.size());
        std::memcpy(idBuf, id.data(), copyLen);
    }
    packet.insert(packet.end(), idBuf, idBuf + 6);
    packet.insert(packet.end(), data, data + len);

    if (manager_->isHost()) {
        HSteamNetConnection targetConn = k_HSteamNetConnection_Invalid;
        {
            std::lock_guard<std::mutex> lock(clientsMutex_);
            auto it = idToConn_.find(id);
            if (it != idToConn_.end()) {
                targetConn = it->second;
            }
        }
        if (targetConn == k_HSteamNetConnection_Invalid) {
            return;
        }
        interfacePtr->SendMessageToConnection(
            targetConn,
            packet.data(),
            static_cast<uint32>(packet.size()),
            k_nSteamNetworkingSend_UnreliableNoNagle |
                k_nSteamNetworkingSend_NoDelay,
            nullptr);
        return;
    }

    const HSteamNetConnection conn = manager_->getConnection();
    if (conn == k_HSteamNetConnection_Invalid) {
        return;
    }
    interfacePtr->SendMessageToConnection(
        conn,
        packet.data(),
        static_cast<uint32>(packet.size()),
        k_nSteamNetworkingSend_UnreliableNoNagle |
            k_nSteamNetworkingSend_NoDelay,
        nullptr);
}

void UDPForwarder::handleTunnelPacket(HSteamNetConnection conn, const char* data, size_t len) {
    if (len < 6) {
        return;
    }

    std::string id(data, 6);
    auto payload = std::make_shared<std::vector<char>>(data + 6, data + len);

    boost::asio::post(io_context_, [this, conn, id = std::move(id), payload]() {
        if (!running_ || !manager_) {
            return;
        }

        if (manager_->isHost()) {
            if (conn == k_HSteamNetConnection_Invalid) {
                return;
            }

            std::shared_ptr<TargetSession> session;
            {
                std::lock_guard<std::mutex> lock(clientsMutex_);
                idToConn_[id] = conn;
                auto it = targetSessions_.find(id);
                if (it != targetSessions_.end()) {
                    session = it->second;
                } else {
                    session = std::make_shared<TargetSession>(io_context_);
                    session->socket.open(udp::v4());
                    session->socket.bind(udp::endpoint(udp::v4(), 0));
                    targetSessions_[id] = session;
                }
            }

            if (session && !session->receiving) {
                session->receiving = true;
                startTargetReceive(id, session);
            }

            const udp::endpoint targetEndpoint(
                boost::asio::ip::address_v4::loopback(),
                static_cast<unsigned short>(targetPort_));

            if (!session) {
                return;
            }

            session->socket.async_send_to(
                boost::asio::buffer(*payload), targetEndpoint,
                [payload](const boost::system::error_code&, std::size_t) {});
            return;
        }

        udp::endpoint endpoint;
        bool found = false;
        ClientKey key;
        {
            std::lock_guard<std::mutex> lock(clientsMutex_);
            auto it = idToClient_.find(id);
            if (it != idToClient_.end()) {
                key = it->second;
                found = true;
            }
        }
        if (!found) {
            return;
        }
        endpoint = key.endpoint;
        socket_.async_send_to(
            boost::asio::buffer(*payload), endpoint,
            [payload](const boost::system::error_code&, std::size_t) {});
    });
}
