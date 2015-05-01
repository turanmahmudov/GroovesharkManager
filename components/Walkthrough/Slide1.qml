/*
 * Copyright (C) 2014-2015
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Nekhelesh Ramananthan <nik90@ubuntu.com>
 *      Victor Thompson <victor.thompson@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Upstream location:
 * https://github.com/krnekhelesh/flashback
 */

import QtQuick 2.3
import Ubuntu.Components 1.1

// Slide 1
Component {
    id: slide1

    Item {
        id: slide1Container

        UbuntuShape {
            anchors {
                top: parent.top
                topMargin: units.gu(6)
                horizontalCenter: parent.horizontalCenter
            }
            height: (parent.height - bodyText.contentHeight - introductionText.height - 4*units.gu(4))/2
            image: Image {
                id: centerImage
                source: Qt.resolvedUrl("../../grooveshark@512.png")
            }
            radius: "medium"
            width: height
        }

        Label {
            id: introductionText
            anchors {
                bottom: bodyText.top
                bottomMargin: units.gu(4)
            }
            color: "#fff"
            elide: Text.ElideRight
            fontSize: "x-large"
            horizontalAlignment: Text.AlignHLeft
            maximumLineCount: 2
            text: i18n.tr("Grooveshark Manager")
            width: units.gu(36)
            wrapMode: Text.WordWrap
        }

        Label {
            id: bodyText
            anchors {
                bottom: parent.bottom
                bottomMargin: units.gu(10)
            }
            color: "#fff"
            fontSize: "large"
            height: contentHeight
            horizontalAlignment: Text.AlignHLeft
            text: i18n.tr("Take a tour or skip to browse now.")
            width: units.gu(36)
            wrapMode: Text.WordWrap
        }
    }
}
