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
import QtCore

import Apx.Application

/*
    EMIP instrument panel (engine, fuel, annunciators) and the Sensors page.
    Settings: EmipSettings, a Fact tree attached to the plugin entry in Preferences
    (GitHub plugins, Alexandr-one/emip) or to Tools on a GCS without that entry; defaults in EmipConfig.qml.
    The panel is off by default: on its first start the plugin switches itself off in the
    plugins settings (the standard per-plugin switch) and remembers that with a stamp in
    QSettings, nothing is shown that time. Switch it on in Preferences, Plugins, EMIP: the
    plugin is loaded again and registers the panels and the FP page.
*/

AppPlugin {
    id: plugin

    readonly property bool isEmipPanel: true
    title: qsTr("EMIP")
    descr: qsTr("Engine and fuel instruments")
    icon: "gauge"

    unloadOnHide: true
    visible: false // shown by the instruments layout once registered
    uiComponent: "main"

    // first start: switch the plugin off (standard plugins setting) once, stamp it in QSettings
    Settings {
        id: stamp
        category: "Emip"
        property bool initialized: false
    }
    readonly property var pluginSwitch: apx.settings.application.plugins.emip

    onConfigure: {
        if(!stamp.initialized){
            stamp.initialized = true
            if(pluginSwitch) pluginSwitch.value = false
            return
        }
        register()
    }
    // the panels in the instruments area and the fuel pumps page in the Controls panel
    function register()
    {
        ui.main.add(plugin, GroundControl.Layout.Instrument)
        ui.main.add(sensors, GroundControl.Layout.Instrument)
        if(typeof(ui.main.addControlPage) === "function")
            ui.main.addControlPage({ "name": "FP", "mode": "", "source": Qt.resolvedUrl("EmipPageFP.qml") })
    }

    // settings menu: under the GitHub plugin entry when the GCS provides it, Tools otherwise
    readonly property alias config: instrumentConfig
    readonly property alias settings: emipSettings
    EmipSettings {
        id: emipSettings
        Component.onCompleted: {
            if(plugin.pluginSettings){
                parentFact = plugin.pluginSettings
            }else{
                section = qsTr("System features")
                parentFact = apx.tools
            }
        }
    }
    Component.onCompleted: application.registerUiComponent(plugin, "emip") // ui.emip for the FP page

    EmipConfig {
        id: instrumentConfig
        rpmPaths: [emipSettings.rpmPath]
        pumpVoltagePaths: [emipSettings.pumpVoltagePath]
        throttleFeedbackPaths: [emipSettings.throttlePath]
        engineStatusPaths: [emipSettings.engineStatusPath]
        egtPaths: [emipSettings.egtPath]
        fuelTotalPaths: [emipSettings.totalPath]
        fuel1Paths: [emipSettings.tankPaths[0]]
        fuel2Paths: [emipSettings.tankPaths[1]]
        fuel3Paths: [emipSettings.tankPaths[2]]
        relay1Paths: [emipSettings.relay1Path]
        relay2Paths: [emipSettings.relay2Path]
        relay3Paths: [emipSettings.relay3Path]
        satcomPaths: [emipSettings.satcomPath]
        batteryPaths: [emipSettings.batteryPath]
        rpm100: emipSettings.rpm100
        rpmMin: emipSettings.rpmMin
        rpmMax: emipSettings.rpmMax
        rpmLowRed: emipSettings.rpmLowRed
        rpmLowYellow: emipSettings.rpmLowYellow
        rpmHighYellow: emipSettings.rpmHighYellow
        rpmHighRed: emipSettings.rpmHighRed
        egtMin: emipSettings.egtMin
        egtMax: emipSettings.egtMax
        egtLow: emipSettings.egtLow
        egtHigh: emipSettings.egtHigh
        rpmMultiplier: emipSettings.rpmMultiplier
        egtMultiplier: emipSettings.egtMultiplier
        fuelScaleMax: emipSettings.scaleMax
        tankCapacities: emipSettings.tankCapacities
        tankLow: emipSettings.tankLow
        tankNames: emipSettings.tankNames
        fuelTotalIsSum: emipSettings.totalIsSum
        fuelTotalName: emipSettings.totalName
        fuelTotalLow: emipSettings.totalLow
        fuelTotalCritical: emipSettings.totalCritical
        fuelTotalHysteresis: emipSettings.totalHysteresis
        batterySeries: emipSettings.batterySeries
        batteryWarningCellVoltage: emipSettings.batteryWarning
        batteryCriticalCellVoltage: emipSettings.batteryCritical
        batteryCellHysteresis: emipSettings.batteryHysteresis
        pumpAbsoluteHigh: emipSettings.pumpAbsoluteHigh
        pumpSwitchPaths: emipSettings.pumpSwitchPaths
    }

    EmipTelemetry {
        id: instrumentData
        unit: apx.fleet.current
        config: instrumentConfig
    }

    // second instrument: automatic sensors reset
    EmipSensors {
        id: sensors
        settings: emipSettings
    }

    sourceComponent: EmipPanel {
        telemetry: instrumentData
        config: instrumentConfig
    }
}
