require("../dist/app.scss");

import Calendar from './elm/calendar';
import { Main } from '../elmsrc/Main.elm'

$(document).ready(function() {
    var node = document.getElementById('main');
    var app = Main.embed(node);

    var cal = new Calendar(app.ports.sched)
})
