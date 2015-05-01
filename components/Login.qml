import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Content 0.1
import QtMultimedia 5.0
import "../js/scripts.js" as Scripts
import "../js/sha1func.js" as Func

Item {
    id: login

    Rectangle {
        id: header
        width: headerLabel.contentWidth
        height: headerLabel.contentHeight + units.gu(1)
        anchors.top: parent.top
        anchors.topMargin: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"
        Label {
            id: headerLabel
            anchors.left: parent.left
            anchors.top: parent.top
            text: "Sign in to Grooveshark"
            fontSize: "x-large"
        }
    }

    Rectangle {
        id: formFields
        width: units.gu(30)
        height: usernameLabel.contentHeight + username.height + passwordLabel.contentHeight + password.height + signinButton.height + units.gu(7)
        anchors.top: header.bottom
        anchors.topMargin: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"
        Label {
            id: usernameLabel
            anchors.left: parent.left
            anchors.top: parent.top
            text: "Username or Email:"
        }
        TextField {
            id: username
            width: parent.width
            anchors.left: parent.left
            anchors.top: usernameLabel.bottom
            anchors.topMargin: units.gu(1)
        }
        Label {
            id: passwordLabel
            anchors.left: parent.left
            anchors.top: username.bottom
            anchors.topMargin: units.gu(2)
            text: "Password:"
        }
        TextField {
            id: password
            width: parent.width
            anchors.left: parent.left
            anchors.top: passwordLabel.bottom
            anchors.topMargin: units.gu(1)
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        }
        Button {
            id: signinButton
            width: parent.width
            anchors.top: password.bottom
            anchors.topMargin: units.gu(2)
            text: "Sign in"
            gradient: Gradient {
              GradientStop { position: 0.0; color: "#F99A33" }
              GradientStop { position: 1.0; color: "#F45400" }
            }
            onClicked: {
                var usernameText = username.text;
                var passwordText = password.text;
                Scripts.login(usernameText, passwordText);
            }

        }
    }

    Rectangle {
        id: note
        width: formFields.width + units.gu(10)
        anchors.top: formFields.bottom
        anchors.topMargin: units.gu(3)
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"
        Text {
            id: noteLabel
            anchors.left: parent.left
            anchors.top: parent.top
            width: note.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "There is no public Grooveshark APIs, so the application has to store your login credentials locally to login your Grooveshark account everytime you launch the application."
        }
    }
}
