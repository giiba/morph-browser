/*
 * Copyright 2019 ubports.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.6
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1

BrowserPage {
    id: customUserAgentsPage

    property bool selectMode
    signal done()
    signal reload()

    title: i18n.tr("Custom User Agents")

    showBackAction: !selectMode

    leadingActions: [
        Action {
            objectName: "close"
            iconName: "close"
            onTriggered: customUserAgentsPage.selectMode = false
        }
    ]

    trailingActions: [
        Action {
            text: i18n.tr("Select all")
            iconName: "select"
            visible: selectMode
            onTriggered: {
                if (customUserAgentsListView.ViewItems.selectedIndices.length === customUserAgentsListView.count) {
                    customUserAgentsListView.ViewItems.selectedIndices = []
                } else {
                    var indices = []
                    for (var i = 0; i < customUserAgentsListView.count; ++i) {
                        indices.push(i)
                    }
                    customUserAgentsListView.ViewItems.selectedIndices = indices
                }
            }
        },
        Action {
            text: i18n.tr("Delete")
            iconName: "delete"
            visible: selectMode
            enabled: customUserAgentsListView.ViewItems.selectedIndices.length > 0
            onTriggered: {
                var toDelete = []
                for (var i = 0; i < customUserAgentsListView.ViewItems.selectedIndices.length; i++) {
                    var selectedDomainSetting = customUserAgentsListView.model.get(customUserAgentsListView.ViewItems.selectedIndices[i])
                    toDelete.push(selectedDomainSetting.domain)
                }
                for (var i = 0; i < toDelete.length; i++) {
                    UserAgentsModel.removeEntry(toDelete[i])
                }
                customUserAgentsListView.ViewItems.selectedIndices = []
                customUserAgentsPage.selectMode = false
            }
        },
        Action {
            iconName: "edit"
            visible: !selectMode
            enabled: customUserAgentsListView.count > 0
            onTriggered: {
                selectMode = true
            }
        },
        Action {
            iconName: "add"
            visible: !selectMode
            onTriggered: {
                var promptDialog = PopupUtils.open(Qt.resolvedUrl("PromptDialog.qml"), customUserAgentsPage);
                promptDialog.title = i18n.tr("New User Agent")
                promptDialog.message = i18n.tr("Add the name for the new user agent")
                promptDialog.accept.connect(function(text) {
                    if (text !== "") {
                        UserAgentsModel.insertEntry(text, "");
                        reload();
                    }
                });
            }
        }
    ]


    onBack: {
        selectMode = false;
        done();
    }

    ListView {
        id: customUserAgentsListView
        anchors.fill: parent
        focus: true
        model: SortFilterModel {
            id: sortedUserAgentsModel
            model: UserAgentsModel
            sort.property: "name"
            sort.order: Qt.AscendingOrder
        }

        ViewItems.selectMode: customUserAgentsPage.selectMode

        delegate: ListItem {
            id: item
            readonly property bool isCurrentItem: item.ListView.isCurrentItem
            //readonly property string domain: model.domain
            //readonly property int userAgentId: model.userAgentId
            height: isCurrentItem ? layout.height : units.gu(5)
            color: isCurrentItem ? theme.palette.selected.base : theme.palette.normal.background

            MouseArea {
                anchors.fill: parent
                onClicked: customUserAgentsListView.currentIndex = index
            }

            SlotsLayout {
                id: layout
                width: parent.width

                mainSlot:

                    Column {

                    spacing: units.gu(2)


                    Label {
                        width: parent.width
                        height: units.gu(1)
                        text: model.name
                        visible: ! item.ListView.isCurrentItem
                    }

                    TextField {
                        text: model.name
                        onTextChanged: UserAgentsModel.setUserAgentName(model.id, text)
                    }

                    TextArea {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: model.userAgentString
                        placeholderText: i18n.tr("user agent string")
                        onTextChanged: UserAgentsModel.setUserAgentString(model.id, text)
                    }
                }
            }


            leadingActions: deleteActionList

            ListItemActions {
                id: deleteActionList
                actions: [
                    Action {
                        objectName: "leadingAction.delete"
                        iconName: "delete"
                        enabled: true
                        onTriggered: UserAgentsModel.removeEntry(model.id)
                    }
                ]
            }
        }
    }

    Scrollbar {
        flickableItem: customUserAgentsListView
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: customUserAgentsListView.count == 0
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No custom user agents available")
    }
}
