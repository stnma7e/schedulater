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
      defaultDate: '2000-01-07',
      columnFormat: 'dddd',
      timezone: "UTC",
      firstDay: 1,
      aspectRatio: 2.6*(this.last_width/1008),
      windowResize: function(view) {
        var multiplier = $(window).width() / $('#calendar').last_width;
        $('#calendar').fullCalendar({aspectRatio: 2.6*multiplier})
      },
      events: function(start, end, timezone, callback) {
        var events = [];
        if (typeof this.props.events != "undefined") {
          console.log(colorList);
          var last_title = "";
          var colorIdx = 0;
          events = this.props.events.map((event) => event);
          // they should be in order of title from the server's output
          for (let event of events) {
            console.log(event)
            if (event.title !== last_title) {
              last_title = event.title;
              colorIdx++;
            }
            event.color = colorList[colorIdx].background;
            event.textColor = colorList[colorIdx].text;
          };
        }
        callback(events)
      }.bind(this)
    })
  }

  render() {
    return <div id='calendar'></div>
  }

  componentDidUpdate(prevProps, prevState) {
    $('#calendar').fullCalendar('refetchEvents');
  }
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
