import fullCalendar from 'fullcalendar';

export default class Calendar {
    constructor(divId, schedUpdateFunction, lockCourseIndex) {
        this.transform_event_data = this.transform_event_data.bind(this)
        this.extract_events_from_object = this.extract_events_from_object.bind(this)

        this.class_colors = new Map()
        this.sched = [];
        this.divId = divId;

        this.minHours = 7;
        this.maxHours = 19;

        schedUpdateFunction.subscribe((newSched) => {
            this.sched = newSched.map(x => {
                // give each event an individual title instead of a collective one
                return Object.assign(x[1], {
                    title: x[0]
                })
            })

            $('#' + divId).fullCalendar('refetchEvents');

        });

        $('#' + divId).last_width = $(window).width();

        $('#' + divId).fullCalendar({
            defaultView: 'agendaWeek',
            minTime: this.minHours + ":00:00",
            maxTime: this.maxHours + ":00:00",
            allDaySlot: false,
            header: false,
            weekends: false,
            defaultDate: '2000-01-07',
            columnFormat: 'dddd',
            firstDay: 1,
            aspectRatio: 2.6 * (this.last_width / 1008),
            windowResize: function(view) {
                var multiplier = $(window).width() / $('#' + divId).last_width;
                $('#' + divId).fullCalendar({
                    aspectRatio: 2.6 * multiplier
                })
            },
            events: this.transform_event_data,
            eventClick: function(calEvent, jsEvent, view) {
                lockCourseIndex.send(calEvent.id);
            }.bind(this)
        })
    }

    transform_event_data(start, end, timezone, callback) {
        if (this.sched.length >= 1) {
            let calendar_events = this.extract_events_from_object(this.sched);

            if (calendar_events.needsWeekend) {
                $('#' + this.divId).fullCalendar('option', 'weekends', true)
            } else {
                $('#' + this.divId).fullCalendar('option', 'weekends', false)
            }

            colorize_events(calendar_events.events, this.class_colors);

            callback(calendar_events.events)
        } else {
            callback([])
        }
    }

    extract_events_from_object(events) {
        let newEvents = {
            events: [],
            needsWeekend: false,
        }

        const days = [
            (1 << 0), // M
            (1 << 1), // T
            (1 << 2), // W
            (1 << 3), // R
            (1 << 4), // F
            (1 << 5), // S
            (1 << 6), // U
        ];

        for (const event of events) {
            for (const daytime of event.daytimes) {
                for (var i = 0; i < 7; i++) {
                    var day = null;
                    const daysAnd = daytime.days & days[i];
                    if ((daytime.days & days[i]) == 0) {
                        continue;
                    }

                    day = i + 3;
                    if (i >= 5) {
                        newEvents.needsWeekend = true;
                    }

                    const startHours = Math.floor(daytime.startEndTime.start / 60);
                    const startMins = daytime.startEndTime.start % 60;
                    const endHours = Math.floor(daytime.startEndTime.end / 60);
                    const endMins = daytime.startEndTime.end % 60;

                    if (startHours < this.minHours*60) {
                        this.minHours = startHours;
                    }
                    if (endHours + endMins > this.minHours*60) {
                        this.minHours = Math.ceil((endHours + endMins) / 60);
                    }

                    let startDate = new Date('Jan ' + day + ', 2000');
                    let endDate = new Date('Jan ' + day + ', 2000');
                    startDate.setHours(parseInt(startHours));
                    startDate.setMinutes(parseInt(startMins));
                    endDate.setHours(parseInt(endHours));
                    endDate.setMinutes(parseInt(endMins));

                    newEvents.events.push({
                        'id': event.crn,
                        'title': event.title,
                        'start': startDate,
                        'end': endDate
                    })
                }
            }
        }

        return newEvents;
    }
}

function colorize_events(events, color_map) {
    for (let event of events) {
        // if the class already has an assigned color, use it
        if (color_map.has(event.title)) {
            let color = color_map.get(event.title)
            event.color = color.background
            event.textColor = color.text
        } else {
            // we need to find a color that is not in use by any other class so far
            for (let color of colorList) {
                if ([...color_map.values()].filter((x) => {
                        return x == color
                    }).length < 1) {
                    color_map.set(event.title, color)
                    event.color = color.background
                    event.textColor = color.text;
                    break
                }
            }
        }
    };
}

const colorList = function() {
    let addColor = (background, text) => {
        return {
            "background": background,
            "text": text
        }
    };

    var arr = [];
    arr.push(addColor("orangered", "black"))
    arr.push(addColor("aquamarine", "black"))
    arr.push(addColor("lightskyblue", "black"))
    arr.push(addColor("blueviolet", "black"))
    arr.push(addColor("cyan", "black"))
    arr.push(addColor("yellow", "black"))
    arr.push(addColor("violet", "black"))
    arr.push(addColor("rosybrown", "black"))
    arr.push(addColor("forestgreen", "black"))

    return arr;
}()
