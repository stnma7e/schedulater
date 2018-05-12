require("../dist/app.scss");

import Calendar from './js/calendar';
import ClockPicker from './js/clockpicker';
import { Main } from './Main.elm';

$(document).ready(function() {
    var node = document.getElementById('main');
    var app = Main.embed(node);
    new Promise(resolve => setTimeout(resolve, 50)).then(() => {
        var cal = new Calendar("calendar", app.ports.sched, app.ports.lockSection);
        var startTimePicker = new ClockPicker("startTime", app.ports.startTime);
        var startTimePicker = new ClockPicker("endTime", app.ports.endTime);
    });
})
