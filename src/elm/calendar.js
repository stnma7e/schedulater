import fullCalendar from 'fullcalendar';

export default class Calendar {
    constructor(schedUpdateFunction, lockCourseIndex) {
        this.transform_event_data = this.transform_event_data.bind(this)

        this.class_colors = new Map()
        this.sched = [];

        schedUpdateFunction.subscribe((newSched) => {
            this.sched = newSched.map(x => {
                // give each event an individual title instead of a collective one
                return Object.assign(x[1], {
                    title: x[0]
                })
            })

            $('#calendar').fullCalendar('refetchEvents');

        });

        $('#calendar').last_width = $(window).width();

        $('#calendar').fullCalendar({
            defaultView: 'agendaWeek',
            minTime: "7:00:00",
            maxTime: "22:00:00",
            allDaySlot: false,
            header: false,
            weekends: false,
            defaultDate: '2000-01-07',
            columnFormat: 'dddd',
            firstDay: 1,
            aspectRatio: 2.6 * (this.last_width / 1008),
            windowResize: function(view) {
                var multiplier = $(window).width() / $('#calendar').last_width;
                $('#calendar').fullCalendar({
                    aspectRatio: 2.6 * multiplier
                })
            },
            events: this.transform_event_data,
            eventClick: function(calEvent, jsEvent, view) {
                lockCourseIndex(calEvent.id)
            }.bind(this)
        })
    }

    transform_event_data(start, end, timezone, callback) {
        if (this.sched.length >= 1) {
            let calendar_events = extract_event_data(this.sched);

            if (calendar_events.needsWeekend) {
                $('#calendar').fullCalendar('option', 'weekends', true)
            } else {
                $('#calendar').fullCalendar('option', 'weekends', false)
            }

            colorize_events(calendar_events.events, this.class_colors);

            callback(calendar_events.events)
        } else {
            callback([])
        }
    }
}

function extract_event_data(events) {
    let newEvents = {
        events: [],
        needsWeekend: false,
    }

    for (let event of events) {
        let daytimes = event.daytimes.split(" ");
        for (let daytime of daytimes) {
            let times = daytime.split("|");
            let startEnd = times[0].split(",");

            var startTime = startEnd[0].split(':');
            var endTime = startEnd[1].split(':');
            var startHours = startTime[0];
            var startMins = startTime[1];
            var endHours = endTime[0];
            var endMins = endTime[1];

            for (var i = 0; i < times[1].length; i++) {
                let day = null;
                switch (times[1][i]) {
                    // mapping the day of the week to the day of the first week of
                    // Jan, 2000 (which is how the calendar is set up)
                    case "M":
                        day = "3";
                        break
                    case "T":
                        day = "4";
                        break
                    case "W":
                        day = "5";
                        break
                    case "R":
                        day = "6";
                        break
                    case "F":
                        day = "7";
                        break
                    case "S":
                        day = "8";
                        newEvents.needsWeekend = true;
                        break
                    case "U":
                        day = "9";
                        newEvents.needsWeekend = true;
                        break
                };

                let startDate = new Date('Jan ' + day + ', 2000')
                let endDate = new Date('Jan ' + day + ', 2000')
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
