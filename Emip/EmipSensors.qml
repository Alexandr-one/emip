/*
 * APX Autopilot project <http://docs.uavos.com>
 *
 * Copyright (c) 2003-2020, Aliaksei Stratsilatau <sa@uavos.com>
 * All rights reserved
 *
 * This file is part of APX Ground Control.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import QtCore

import Apx.Common
import Apx.Application
import APX.Facts

/*
    Sensors page of the EMIP plugin (automatic magnetometer and barometer reset, guide sliders),
    the former SensorsReset user plugin. Shown as a separate instrument next to the EMIP panel.
    The switches are the Sensors group of the EMIP settings.
    A Loader like AppPlugin: the instruments layout copies the item properties into its model
    when the page is added, the content is created later.
*/
Loader {
    id: plugin
    active: true

    property string title: qsTr("Sensors")
    property string descr: qsTr("Automatic sensors reset")
    property string icon: "restart"

    property var settings: null // EmipSettings
    readonly property bool magReset: settings ? settings.magReset : false
    readonly property bool baroReset: settings ? settings.baroReset : false

    readonly property int resetInterval: 5000

    readonly property var unit: apx.fleet.current
    readonly property var mandala: unit ? unit.mandala : null

    readonly property var magFact: mandala ? mandala.fact("est.ins.mag", true) : null
    readonly property var statushFact: mandala ? mandala.fact("est.ins.statush", true) : null
    readonly property var procModeFact: mandala ? mandala.fact("cmd.proc.mode", true) : null
    readonly property var procStageFact: mandala ? mandala.fact("cmd.proc.stage", true) : null
    readonly property var scrModeFact: mandala ? mandala.fact("sns.scr.s10", true) : null
    readonly property var scrAltFact: mandala ? mandala.fact("sns.scr.s11", true) : null
    readonly property var tdelayFact: mandala ? mandala.fact("cmd.guide.tdelay", true) : null
    readonly property var tdistFact: mandala ? mandala.fact("cmd.guide.tdist", true) : null

    readonly property string magState: magFact ? magFact.text : ""
    readonly property bool magBlocked: magState === "blocked"

    readonly property real statush: statushFact ? Number(statushFact.value) : 0
    readonly property bool baroFault: (((statush >>> 0) >>> 11) & 1) === 1

    readonly property string procMode: procModeFact ? procModeFact.text : ""
    readonly property int procStage: procStageFact ? Number(procStageFact.value) : 0
    readonly property bool magAllowed: procMode === "TAXI"
                                       || (procMode === "TAKEOFF" && (procStage === 1 || procStage === 2))


    property var guideModeFact: null
    property var guideAltFact: null
    property var remagCmd: null
    property var rebaroCmd: null

    readonly property int guideMode: guideModeFact ? Number(guideModeFact.value) : 0
    readonly property string guideModeText: guideModeFact ? guideModeFact.text : ""
    readonly property real guideAlt: guideAltFact ? Number(guideAltFact.value) : 0

    property var keep: []
    function hold(f)
    {
        if (f && keep.indexOf(f) < 0)
            keep.push(f)
        return f
    }
    function pruneKeep()
    {
        for (var i = keep.length - 1; i >= 0; --i)
            if (!keep[i])
                keep.splice(i, 1)
    }
    function modelFact(model, row)
    {
        return hold(model.data(model.index(row, 0), Qt.UserRole + 1)) // modelData
    }
    function modelChild(fact, name)
    {
        var m = fact ? fact.model : null
        if (!m)
            return null
        var cnt = m.rowCount()
        for (var i = 0; i < cnt; ++i) {
            var f = modelFact(m, i)
            if (f && f.name === name)
                return f
        }
        return null
    }
    function modelPath(fact, path)
    {
        var f = fact
        var parts = path.split('.')
        for (var i = 0; i < parts.length && f; ++i)
            f = modelChild(f, parts[i])
        return f
    }
    function actionChild(fact, name)
    {
        var m = fact ? fact.actionsModel : null
        if (!m)
            return null
        var cnt = m.rowCount()
        for (var i = 0; i < cnt; ++i) {
            var f = modelFact(m, i)
            if (f && f.name === name)
                return f
        }
        return null
    }
    function scanNodes()
    {
        var gm = null, ga = null, cm = null, cb = null
        pruneKeep()
        var nodes = unit ? unit.nodes : null
        var nm = nodes ? nodes.model : null
        if (nm) {
            var cnt = nm.rowCount()
            for (var i = 0; i < cnt; ++i) {
                var n = modelFact(nm, i)
                if (!n)
                    continue
                if (!gm) {
                    gm = modelPath(n, "shiva.guide.mode")
                    ga = modelPath(n, "shiva.guide.altitude")
                }
                if (!cm) {
                    var tools = actionChild(n, "tools")
                    // "usr" is a section, flattened in the tools model
                    var ins = modelChild(tools, "ins")
                    if (!ins)
                        ins = modelPath(tools, "usr.ins")
                    if (ins) {
                        cm = modelChild(ins, "remag")
                        cb = modelChild(ins, "rebaro")
                    }
                }
            }
        }
        if (guideModeFact !== gm)
            guideModeFact = gm
        if (guideAltFact !== ga)
            guideAltFact = ga
        if (remagCmd !== cm)
            remagCmd = cm
        if (rebaroCmd !== cb)
            rebaroCmd = cb
    }
    readonly property bool nodesFound: guideModeFact && remagCmd && rebaroCmd ? true : false

    Timer {
        id: scanTimer
        interval: 200
        onTriggered: plugin.scanNodes()
    }
    onUnitChanged: scanTimer.restart()
    Connections {
        target: plugin.unit ? plugin.unit.nodes : null
        function onSizeChanged() { scanTimer.restart() }
    }
    Timer {
        interval: 1000
        repeat: true
        running: plugin.unit && !plugin.nodesFound ? true : false
        onTriggered: plugin.scanNodes()
    }

    Component.onCompleted: {
        scanNodes()
        syncGuide()
        var reg = application.jsexec("(function(o){ sensorsReset = o })")
        if (typeof reg === "function")
            reg(plugin)
    }

    function syncGuide()
    {
        if (scrModeFact && guideModeFact && Number(scrModeFact.value) !== guideMode)
            scrModeFact.setRawValueLocal(guideMode)
        if (scrAltFact && guideAltFact && Number(scrAltFact.value) !== guideAlt)
            scrAltFact.setRawValueLocal(guideAlt)
    }
    Connections {
        target: plugin.scrModeFact
        function onValueChanged() { syncTimer.restart() }
    }
    Connections {
        target: plugin.scrAltFact
        function onValueChanged() { syncTimer.restart() }
    }
    Timer {
        id: syncTimer
        interval: 500
        onTriggered: plugin.syncGuide()
    }
    onGuideModeChanged: syncGuide()
    onGuideAltChanged: syncGuide()
    onGuideModeFactChanged: syncGuide()
    onGuideAltFactChanged: syncGuide()
    onScrModeFactChanged: syncGuide()
    onScrAltFactChanged: syncGuide()

    property double lastMagReset: 0
    property double lastBaroReset: 0

    function sendReset(cmd, title)
    {
        unit.message(qsTr("Auto reset") + ": " + (cmd ? cmd.title : title),
                     AppNotify.FromUnit | AppNotify.Important)
        if (cmd && !unit.isReplay)
            cmd.trigger()
    }
    function check()
    {
        if (!unit)
            return
        var now = Date.now()
        if (magReset && magBlocked && magAllowed
                && (now - lastMagReset) >= resetInterval) {
            lastMagReset = now
            sendReset(remagCmd, qsTr("Reset magnetometer"))
        }
        if (baroReset && baroFault
                && (now - lastBaroReset) >= resetInterval) {
            lastBaroReset = now
            sendReset(rebaroCmd, qsTr("Reset barometer"))
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: magReset || baroReset
        onTriggered: plugin.check()
    }
    onMagBlockedChanged: check()
    onBaroFaultChanged: check()
    onMagAllowedChanged: check()

    sourceComponent: Component {
        Rectangle {
            id: view
            color: "#000"
            border.width: 0
            implicitWidth: 600
            implicitHeight: 300

            readonly property real fsTitle: Style.fontSize * 1.3
            readonly property real fsValue: Style.fontSize * 1.3

            readonly property color cCard: "#1c2228"
            readonly property color cCardBorder: "#2f3a44"
            readonly property color cAccent: Material.color(Material.LightGreen)

            component Card: Rectangle {
                id: card
                property string title
                property bool hasSwitch: false
                property bool checked: false
                signal toggled(bool checked)
                default property alias content: col.data
                property bool fill: true

                Layout.fillWidth: true
                Layout.fillHeight: fill
                Layout.minimumHeight: col.implicitHeight + Style.spacing * 6
                Layout.preferredHeight: col.implicitHeight + Style.spacing * 6
                radius: Style.spacing
                color: view.cCard
                border.width: 1
                border.color: view.cCardBorder

                ColumnLayout {
                    id: col
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Style.spacing * 3
                    spacing: Style.spacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.spacing * 2
                        Text {
                            id: titleText
                            text: card.title
                            Layout.fillWidth: true
                            font: apx.font_narrow(view.fsTitle, true)
                            color: Material.primaryTextColor
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        Switch {
                            id: sw
                            visible: card.hasSwitch
                            checked: card.checked
                            onToggled: card.toggled(checked)
                            padding: 0
                            Material.accent: view.cAccent
                        }
                    }
                }
            }

            component ValueRow: RowLayout {
                id: row
                property var fact: null
                property string title
                property string units
                property real from: 0
                property real to: 10
                readonly property real factValue: fact ? Number(fact.value) : 0

                Layout.fillWidth: true
                spacing: Style.spacing * 2
                enabled: fact ? true : false

                Text {
                    text: row.title
                    Layout.preferredWidth: view.width * 0.25
                    font: apx.font_narrow(view.fsValue)
                    color: Material.primaryTextColor
                    elide: Text.ElideRight
                }
                Slider {
                    id: slider
                    Layout.fillWidth: true
                    from: row.from
                    to: row.to
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    Material.accent: view.cAccent
                    onMoved: {
                        var v = Math.round(value)
                        if (row.fact && Number(row.fact.value) !== v)
                            row.fact.setValue(v)
                    }
                    Binding {
                        target: slider
                        property: "value"
                        value: row.factValue
                        when: !slider.pressed
                        restoreMode: Binding.RestoreNone
                    }
                }
                Text {
                    text: (row.fact ? Math.round(slider.value) : "---") + " " + row.units
                    Layout.preferredWidth: view.width * 0.1
                    font: apx.font_narrow(view.fsValue, true)
                    color: Material.primaryTextColor
                    horizontalAlignment: Text.AlignRight
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.spacing * 2
                spacing: Style.spacing * 2

                Card {
                    title: qsTr("Automatic magnetometer reset")
                    hasSwitch: true
                    checked: plugin.magReset
                    onToggled: (checked) => { if (plugin.settings) plugin.settings.setMagReset(checked) }
                }
                Card {
                    title: qsTr("Automatic barometer reset")
                    hasSwitch: true
                    checked: plugin.baroReset
                    onToggled: (checked) => { if (plugin.settings) plugin.settings.setBaroReset(checked) }
                }
                Card {
                    title: qsTr("Guide")
                    fill: false
                    ValueRow {
                        fact: plugin.tdelayFact
                        title: qsTr("Target delay")
                        units: qsTr("ms")
                    }
                    ValueRow {
                        fact: plugin.tdistFact
                        title: qsTr("Target distance")
                        units: qsTr("m")
                    }
                }
            }
        }
    }
}
