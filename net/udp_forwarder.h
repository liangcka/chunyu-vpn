#pragma once

#include <boost/asio.hpp>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include <isteamnetworkingsockets.h>
#include <steamnetworkingtypes.h>

class SteamNetworkingManager;

using boost::asio::ip::udp;

class UDPForwarder {
public:
    UDPForwarder(int bindPort,
                 int targetPort,
                 SteamNetworkingManager* manager);
    ~UDPForwarder();

    bool start();
    void stop();

    int getClientCount();
    void setClientCountCallback(std::function<void(int)> callback);

    void handleTunnelPacket(HSteamNetConnection conn, const char* data, size_t len);

private:
    struct ClientKey {
        udp::endpoint endpoint;
        bool operator<(const ClientKey& other) const {
            if (endpoint.address().to_string() == other.endpoint.address().to_string()) {
                return endpoint.port() < other.endpoint.port();
            }
            return endpoint.address().to_string() < other.endpoint.address().to_string();
        }
    };

    struct TargetSession;

    void startReceive();
    void startTargetReceive(const std::string& id, const std::shared_ptr<TargetSession>& session);
    void notifyClientCount(int count);
    void sendTunnelPacket(const std::string& id, const char* data, size_t len);

    int bindPort_;
    int targetPort_;
    bool running_;
    boost::asio::io_context io_context_;
    boost::asio::executor_work_guard<boost::asio::io_context::executor_type> work_;
    udp::socket socket_;
    udp::endpoint remoteEndpoint_;
    std::array<char, 65536> recvBuffer_;
    std::thread worker_;
    SteamNetworkingManager* manager_;
    std::function<void(int)> clientCountCallback_;

    std::mutex clientsMutex_;
    std::map<ClientKey, std::string> clientToId_;
    std::map<std::string, ClientKey> idToClient_;
    std::map<std::string, HSteamNetConnection> idToConn_;
    std::map<std::string, std::shared_ptr<TargetSession>> targetSessions_;
};
