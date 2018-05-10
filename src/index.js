require("../dist/app.scss");

import Calendar from './elm/calendar';
import ClockPicker from './elm/clockpicker';
import { Main } from '../elmsrc/Main.elm';

$(document).ready(function() {
    var node = document.getElementById('main');
    var app = Main.embed(node);
    new Promise(resolve => setTimeout(resolve, 50)).then(() => {
        var cal = new Calendar("calendar1", app.ports.sched, app.ports.lockSection);
        var startTimePicker = new ClockPicker("startTime", app.ports.startTime);
        var startTimePicker = new ClockPicker("endTime", app.ports.endTime);
    });
})
