import clockpicker from './jquery-clockpicker.js';

export default class ClockPicker {
    constructor(divId, timeUpdater) {
        $('#' + divId).clockpicker({
            placement: 'top',
            align: 'left',
            donetext: 'Done',
            autoclose: true,
            // twelvehour: true
            afterDone: function() {
                let time = document.getElementById(divId).value;
                timeUpdater.send(time);
            }
        });
    }
}
