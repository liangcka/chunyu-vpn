/*
 * ChunyuVPN - VPN Tool based on Steam Network
 * Copyright (C) 2025 Ji Fuyao and contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "backend.h"
#include "chat_model.h"
#include "lobbies_model.h"
#include "members_model.h"

#include <QCoreApplication>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QIcon>

#ifdef _WIN32
#include <windows.h>
#include <cstring>
#endif

#ifndef CONNECTTOOL_VERSION
#define CONNECTTOOL_VERSION "0.0.0"
#endif

int main(int argc, char *argv[]) {
#ifdef _WIN32
  bool enableTerminal = false;
  for (int i = 1; i < argc; ++i) {
    if (std::strcmp(argv[i], "--terminal") == 0) {
      enableTerminal = true;
      break;
    }
  }
  if (!enableTerminal) {
    FreeConsole();
  }
#endif
  QCoreApplication::setOrganizationName(QStringLiteral("chunyuvpn"));
  QCoreApplication::setApplicationName(QStringLiteral("chunyuvpn"));
  QCoreApplication::setApplicationVersion(QStringLiteral(CONNECTTOOL_VERSION));

  QApplication app(argc, argv);
  app.setWindowIcon(
      QIcon(QStringLiteral(":/qt/qml/chunyuvpn/qml/ConnectTool/logo.ico")));
  QQuickStyle::setStyle(QStringLiteral("Material"));

  qmlRegisterUncreatableType<FriendsModel>("chunyuvpn", 1, 0, "FriendsModel",
                                           "Provided by backend");
  qmlRegisterUncreatableType<MembersModel>("chunyuvpn", 1, 0, "MembersModel",
                                           "Provided by backend");
  qmlRegisterUncreatableType<LobbiesModel>("chunyuvpn", 1, 0, "LobbiesModel",
                                           "Provided by backend");
  qmlRegisterUncreatableType<ChatModel>("chunyuvpn", 1, 0, "ChatModel",
                                        "Provided by backend");

  Backend backend;

  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);

  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

  engine.loadFromModule("chunyuvpn", "Main");

  if (!engine.rootObjects().isEmpty()) {
    if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) {
      backend.initializeSound(window);
    }
  }

  return app.exec();
}
