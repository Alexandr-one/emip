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
import APX.Facts

/*
    EMIP settings: a Fact tree attached to the plugin entry in Preferences
    (GitHub plugins, Alexandr-one/emip) or to Tools when the GCS has no such entry.
    Values persist in the application settings; the panel config is bound to them.
*/
Fact {
    id: root
    name: "emip"
    title: qsTr("EMIP")
    descr: qsTr("Engine monitoring panel settings")
    icon: "gauge"
    flags: Fact.Group

    component PathFact: Fact {
        flags: Fact.Text | Fact.PersistentValue
        descr: qsTr("Mandala path")
    }
    component NameFact: Fact {
        flags: Fact.Text | Fact.PersistentValue
        descr: qsTr("Displayed name")
    }
    component NumFact: Fact {
        flags: Fact.Float | Fact.PersistentValue
        precision: 1
        min: 0
    }
    component IntFact: Fact {
        flags: Fact.Int | Fact.PersistentValue
        min: 0
    }
    component BoolFact: Fact {
        flags: Fact.Bool | Fact.PersistentValue
    }

    // values for the panel config
    readonly property var tankPaths: [f_tank1_path.value, f_tank2_path.value, f_tank3_path.value]
    readonly property var tankNames: [f_tank1_name.value, f_tank2_name.value, f_tank3_name.value]
    readonly property var tankCapacities: [Number(f_tank1_capacity.value), Number(f_tank2_capacity.value), Number(f_tank3_capacity.value)]
    readonly property var tankLow: [Number(f_tank1_low.value), Number(f_tank2_low.value), Number(f_tank3_low.value)]
    readonly property bool totalIsSum: f_total_sum.value ? true : false
    readonly property string totalPath: f_total_path.value
    readonly property string totalName: f_total_name.value
    readonly property real totalLow: Number(f_total_low.value)
    readonly property real totalCritical: Number(f_total_critical.value)
    readonly property real totalHysteresis: Number(f_total_hysteresis.value)
    readonly property real scaleMax: Number(f_scale_max.value)

    readonly property string rpmPath: f_rpm_path.value
    readonly property real rpm100: Number(f_rpm_100.value)
    readonly property real rpmMin: Number(f_rpm_min.value)
    readonly property real rpmMax: Number(f_rpm_max.value)
    readonly property real rpmLowRed: Number(f_rpm_low_red.value)
    readonly property real rpmLowYellow: Number(f_rpm_low_yellow.value)
    readonly property real rpmHighYellow: Number(f_rpm_high_yellow.value)
    readonly property real rpmHighRed: Number(f_rpm_high_red.value)
    readonly property real rpmMultiplier: Number(f_rpm_mult.value)
    readonly property string egtPath: f_egt_path.value
    readonly property real egtMin: Number(f_egt_min.value)
    readonly property real egtMax: Number(f_egt_max.value)
    readonly property real egtLow: Number(f_egt_low.value)
    readonly property real egtHigh: Number(f_egt_high.value)
    readonly property real egtMultiplier: Number(f_egt_mult.value)
    readonly property string pumpVoltagePath: f_pump_path.value
    readonly property string throttlePath: f_throttle_path.value
    readonly property string engineStatusPath: f_status_path.value
    readonly property real pumpAbsoluteHigh: Number(f_pump_high.value)

    readonly property string batteryPath: f_bat_path.value
    readonly property int batterySeries: Number(f_bat_series.value)
    readonly property real batteryWarning: Number(f_bat_warning.value)
    readonly property real batteryCritical: Number(f_bat_critical.value)
    readonly property real batteryHysteresis: Number(f_bat_hysteresis.value)

    readonly property var pumpSwitchPaths: [f_sw_pump1.value, f_sw_pump2.value, f_sw_pump3.value, f_sw_manual.value]

    readonly property string relay1Path: f_relay1_path.value
    readonly property string relay2Path: f_relay2_path.value
    readonly property string relay3Path: f_relay3_path.value

    readonly property string satcomPath: f_satcom_path.value

    readonly property bool magReset: f_mag_reset.value ? true : false
    readonly property bool baroReset: f_baro_reset.value ? true : false
    function setMagReset(v) { f_mag_reset.value = v }
    function setBaroReset(v) { f_baro_reset.value = v }

    Fact {
        name: "fuel"
        title: qsTr("Fuel")
        icon: "gas-station"
        flags: Fact.Group
        PathFact { id: f_tank1_path; name: "tank1_path"; title: qsTr("Tank 1 level"); defaultValue: "est.usr.u5" }
        NameFact { id: f_tank1_name; name: "tank1_name"; title: qsTr("Tank 1 name"); defaultValue: "FUEL 1" }
        NumFact { id: f_tank1_capacity; name: "tank1_capacity"; title: qsTr("Tank 1 capacity"); units: "l"; defaultValue: 16.7 }
        NumFact { id: f_tank1_low; name: "tank1_low"; title: qsTr("Tank 1 low level"); units: "l"; defaultValue: 2 }
        PathFact { id: f_tank2_path; name: "tank2_path"; title: qsTr("Tank 2 level"); defaultValue: "est.usr.u6" }
        NameFact { id: f_tank2_name; name: "tank2_name"; title: qsTr("Tank 2 name"); defaultValue: "FUEL 2" }
        NumFact { id: f_tank2_capacity; name: "tank2_capacity"; title: qsTr("Tank 2 capacity"); units: "l"; defaultValue: 16.7 }
        NumFact { id: f_tank2_low; name: "tank2_low"; title: qsTr("Tank 2 low level"); units: "l"; defaultValue: 3 }
        PathFact { id: f_tank3_path; name: "tank3_path"; title: qsTr("Tank 3 level"); defaultValue: "est.usr.u7" }
        NameFact { id: f_tank3_name; name: "tank3_name"; title: qsTr("Tank 3 name"); defaultValue: "FUEL 3" }
        NumFact { id: f_tank3_capacity; name: "tank3_capacity"; title: qsTr("Tank 3 capacity"); units: "l"; defaultValue: 16.7 }
        NumFact { id: f_tank3_low; name: "tank3_low"; title: qsTr("Tank 3 low level"); units: "l"; defaultValue: 4 }
        BoolFact { id: f_total_sum; name: "total_sum"; title: qsTr("Total is sum of tanks"); descr: qsTr("Otherwise total level source is used"); defaultValue: false }
        PathFact { id: f_total_path; name: "total_path"; title: qsTr("Total level"); defaultValue: "est.usr.u8" }
        NameFact { id: f_total_name; name: "total_name"; title: qsTr("Total name"); defaultValue: "TOTAL FUEL" }
        NumFact { id: f_total_low; name: "total_low"; title: qsTr("Total low level"); descr: qsTr("LOW FUEL warning"); units: "l"; defaultValue: 10 }
        NumFact { id: f_total_critical; name: "total_critical"; title: qsTr("Total critical level"); descr: qsTr("LOW FUEL alarm"); units: "l"; defaultValue: 5 }
        NumFact { id: f_total_hysteresis; name: "total_hysteresis"; title: qsTr("Low level hysteresis"); units: "l"; defaultValue: 2 }
        IntFact { id: f_scale_max; name: "scale_max"; title: qsTr("Scale max"); descr: qsTr("Tank bars scale"); units: "l"; defaultValue: 16; min: 1 }
    }
    Fact {
        name: "engine"
        title: qsTr("Engine")
        icon: "engine"
        flags: Fact.Group
        PathFact { id: f_rpm_path; name: "rpm_path"; title: qsTr("RPM"); defaultValue: "est.eng.rpm" }
        IntFact { id: f_rpm_100; name: "rpm_100"; title: qsTr("RPM 100%"); descr: qsTr("RPM value shown as 100%"); units: "rpm"; defaultValue: 9600; min: 1 }
        IntFact { id: f_rpm_min; name: "rpm_min"; title: qsTr("RPM scale min"); units: "%"; defaultValue: 25 }
        IntFact { id: f_rpm_max; name: "rpm_max"; title: qsTr("RPM scale max"); units: "%"; defaultValue: 115 }
        IntFact { id: f_rpm_low_red; name: "rpm_low_red"; title: qsTr("RPM low red"); units: "%"; defaultValue: 30 }
        IntFact { id: f_rpm_low_yellow; name: "rpm_low_yellow"; title: qsTr("RPM low yellow"); units: "%"; defaultValue: 35 }
        IntFact { id: f_rpm_high_yellow; name: "rpm_high_yellow"; title: qsTr("RPM high yellow"); units: "%"; defaultValue: 104 }
        IntFact { id: f_rpm_high_red; name: "rpm_high_red"; title: qsTr("RPM high red"); units: "%"; defaultValue: 105 }
        NumFact { id: f_rpm_mult; name: "rpm_mult"; title: qsTr("RPM multiplier"); descr: qsTr("Raw value scale"); precision: 3; defaultValue: 1 }
        PathFact { id: f_egt_path; name: "egt_path"; title: qsTr("EGT"); defaultValue: "sns.eng.egt" }
        IntFact { id: f_egt_min; name: "egt_min"; title: qsTr("EGT scale min"); units: "C"; defaultValue: 350 }
        IntFact { id: f_egt_max; name: "egt_max"; title: qsTr("EGT scale max"); units: "C"; defaultValue: 950 }
        IntFact { id: f_egt_low; name: "egt_low"; title: qsTr("EGT low"); units: "C"; defaultValue: 400 }
        IntFact { id: f_egt_high; name: "egt_high"; title: qsTr("EGT high"); units: "C"; defaultValue: 850 }
        NumFact { id: f_egt_mult; name: "egt_mult"; title: qsTr("EGT multiplier"); descr: qsTr("Raw value scale"); precision: 3; defaultValue: 10 }
        PathFact { id: f_pump_path; name: "pump_path"; title: qsTr("Pump voltage"); defaultValue: "est.usr.u9" }
        PathFact { id: f_throttle_path; name: "throttle_path"; title: qsTr("Throttle feedback"); defaultValue: "est.usrc.c3" }
        PathFact { id: f_status_path; name: "status_path"; title: qsTr("Engine status"); defaultValue: "est.usrc.c2" }
        NumFact { id: f_pump_high; name: "pump_high"; title: qsTr("Pump voltage limit"); descr: qsTr("PUMP LIMIT alarm"); units: "V"; defaultValue: 10.5 }
    }
    Fact {
        name: "power"
        title: qsTr("Power")
        icon: "battery"
        flags: Fact.Group
        PathFact { id: f_bat_path; name: "bat_path"; title: qsTr("Battery voltage"); defaultValue: "sns.pwr.vsys" }
        IntFact { id: f_bat_series; name: "bat_series"; title: qsTr("Cells in series"); defaultValue: 4; min: 1 }
        NumFact { id: f_bat_warning; name: "bat_warning"; title: qsTr("Cell warning voltage"); descr: qsTr("LOW BAT warning"); units: "V"; precision: 2; defaultValue: 3.5 }
        NumFact { id: f_bat_critical; name: "bat_critical"; title: qsTr("Cell critical voltage"); descr: qsTr("LOW BAT alarm"); units: "V"; precision: 2; defaultValue: 3.3 }
        NumFact { id: f_bat_hysteresis; name: "bat_hysteresis"; title: qsTr("Cell voltage hysteresis"); units: "V"; precision: 2; defaultValue: 0.3 }
    }
    Fact {
        name: "switches"
        title: qsTr("Switches")
        descr: qsTr("FP page of the Controls panel")
        icon: "toggle-switch"
        flags: Fact.Group
        PathFact { id: f_sw_pump1; name: "pump1"; title: qsTr("Pump 1"); defaultValue: "ctr.sw.sw5" }
        PathFact { id: f_sw_pump2; name: "pump2"; title: qsTr("Pump 2"); defaultValue: "ctr.sw.sw6" }
        PathFact { id: f_sw_pump3; name: "pump3"; title: qsTr("Pump 3"); defaultValue: "ctr.sw.sw7" }
        PathFact { id: f_sw_manual; name: "manual"; title: qsTr("Manual mode"); defaultValue: "ctr.sw.sw8" }
    }
    Fact {
        name: "release"
        title: qsTr("Release system")
        icon: "parachute"
        flags: Fact.Group
        PathFact { id: f_relay1_path; name: "relay1"; title: qsTr("Launch"); defaultValue: "ctr.ers.launch" }
        PathFact { id: f_relay2_path; name: "relay2"; title: qsTr("Relay"); defaultValue: "est.usrb.b1" }
        PathFact { id: f_relay3_path; name: "relay3"; title: qsTr("Release"); defaultValue: "ctr.ers.rel" }
    }
    Fact {
        name: "radio"
        title: qsTr("Radio status")
        descr: qsTr("SATCOM indication")
        icon: "satellite-uplink"
        flags: Fact.Group
        PathFact { id: f_satcom_path; name: "satcom"; title: qsTr("SATCOM"); defaultValue: "ctr.pwr.satcom" }
    }
    Fact {
        name: "sensors"
        title: qsTr("Sensors")
        descr: qsTr("Automatic sensors reset")
        icon: "restart"
        flags: Fact.Group
        BoolFact { id: f_mag_reset; name: "mag_reset"; title: qsTr("Magnetometer reset"); descr: qsTr("Reset when blocked in TAXI or TAKEOFF"); defaultValue: false }
        BoolFact { id: f_baro_reset; name: "baro_reset"; title: qsTr("Barometer reset"); descr: qsTr("Reset on barometer fault"); defaultValue: false }
    }
}
