require("../dist/app.scss");

import Calendar from './elm/calendar';
import { Main } from '../elmsrc/Main.elm'

$(document).ready(function() {
    var node = document.getElementById('main');
    var app = Main.embed(node);
    new Promise(resolve => setTimeout(resolve, 50)).then(() => {
        var cal = new Calendar("calendar", app.ports.sched, app.ports.lockSection);
    });
})
