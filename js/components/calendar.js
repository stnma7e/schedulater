import React from 'react';
import fullCalendar from 'fullcalendar';

export default class Calendar extends React.Component {
  componentDidMount() {
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
      aspectRatio: 2.6*(this.last_width/1008),
      windowResize: function(view) {
        var multiplier = $(window).width() / $('#calendar').last_width;
        $('#calendar').fullCalendar({aspectRatio: 2.6*multiplier})
      },
      events: transform_event_data.bind(this)
    })
  }

  render() {
    return <div id='calendar'></div>
  }

  componentDidUpdate(prevProps, prevState) {
    $('#calendar').fullCalendar('refetchEvents');
  }
}

function transform_event_data(start, end, timezone, callback) {
  if ( typeof this.props.classes != "undefined"
    && typeof this.props.combo   != "undefined"
  ) {
    let events = applyComboToClasses(this.props.classes, this.props.combo);
    console.log(this.props.combo)
    console.log(events)
    let calendar_events = extract_event_data(events);

    if (calendar_events.needsWeekend) {
      $('#calendar').fullCalendar('option', 'weekends', true)
    } else {
      $('#calendar').fullCalendar('option', 'weekends', false)
    }
    colorize_events(calendar_events.events);

    callback(calendar_events.events)
  } else {
    callback([])
  }
}

function applyComboToClasses(classes, combo) {
  return combo.map((combo_index, course_index) => {
    if (combo_index < 1) {
      return null
    } else {
      return Object.assign(classes[course_index].classes[combo_index - 1], {
        title: classes[course_index].title
      })
    }
  }).filter((x) => x != null)
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
      var startMins  = startTime[1];
      var endHours   = endTime[0];
      var endMins    = endTime[1];

      for (var i = 0; i < times[1].length; i++) {
        let day = null;
        switch (times[1][i]) {
          // mapping the day of the week to the day of the first week of
          // Jan, 2000 (which is how the calendar is set up)
          case "M": day = "3"; break
          case "T": day = "4"; break
          case "W": day = "5"; break
          case "R": day = "6"; break
          case "F": day = "7"; break
          case "S": day = "8";
            newEvents.needsWeekend = true;
            break
          case "U": day = "9";
            newEvents.needsWeekend = true;
            break
        };

        let startDate = new Date('Jan ' + day + ', 2000')
        let endDate   = new Date('Jan ' + day + ', 2000')
        startDate.setHours(parseInt(startHours));
        startDate.setMinutes(parseInt(startMins));
        endDate.setHours(parseInt(endHours));
        endDate.setMinutes(parseInt(endMins));

        newEvents.events.push({
          'id':    event.crn,
          'title': event.title,
          'start': startDate,
          'end':   endDate
        })
      }
    }
  }

  return newEvents;
}

function colorize_events(events) {
  var last_title = "";
  var colorIdx = 0;
  // they should be in order of title from the server's output
  for (let event of events) {
    if (event.title !== last_title) {
      last_title = event.title;
      colorIdx++;
    }
    event.color = colorList[colorIdx].background;
    event.textColor = colorList[colorIdx].text;
  };

  return events
}

const colorList = function() {
  let addColor = (background, text) => {
    return {
      "background": background,
      "text": text
    }
  };

  var arr = [{}];
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
