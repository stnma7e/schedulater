import $ from 'jquery';
import fullCalendar from 'fullcalendar';
import timepicker from 'timepicker';
import React from 'react';
import ReactDOM from 'react-dom';
import {
  Foundation,
  Label
} from 'react-foundation';
import {DataTable} from 'datatables.net';
import {Button} from 'datatables.net-buttons-zf';
import {Select} from 'datatables.net-select';
require('foundation-sites');
require("./dist/app.scss");

class ScheduleCalendar extends React.Component {
  constructor() {
    super();
    this.state = {
      schedNumber: 0,
      schedCount: 0,
      schedule: [],
      courseRequest: {},
      renderedCourses: new Set(),
      lastAddedCourses: []
    };

    this.nextSched = this.nextSched.bind(this);
    this.lastSched = this.lastSched.bind(this);
    this.requestClasses  = this.requestClasses.bind(this);
    this.addClasses  = this.addClasses.bind(this);
    this.removeClasses  = this.removeClasses.bind(this);
    this.removeLastClasses  = this.removeLastClasses.bind(this);
  }

  componentDidMount() {
    $("#start_time").timepicker({
      minTime: "7:00am",
      maxTime: "10:00pm",
      step: 15});
    $("#end_time").timepicker({
      minTime: "7:00am",
      maxTime: "10:00pm",
      step: 15});
  }

  requestClasses(rows) {
    var titles = new Array();
    for (var i=0; i< rows.length; i++) {
      titles.push(rows[i][2]); // course title
    }

    var starter = document.getElementById('start_time');
    var start_time = $('#start_time').timepicker('getTime').toTimeString();
    var end_time   = $('#end_time').timepicker('getTime').toTimeString();
    var times = {
      column: "daytimes",
      exceptions: [start_time+","+end_time],
      allowed: true,
    }

    $.ajax({
      url:'/courses',
      type: "POST",
      data: JSON.stringify({ courses: titles, filters: [times] }),
      success: function(result) {
        var courses = JSON.parse(result);
        console.log("schedCount: ", courses.sched_count);

        if (courses.schedule.length < 1) {
          // if there are no valid schedules possible with the classes requested
          // then it's probably easiest to clear the last added classes
          this.removeLastClasses();
        }

        this.setState({
          schedCount: courses.sched_count,
          schedule:   courses.schedule
        });
      }.bind(this),
      error: function(error) {
        this.removeLastClasses()
      }.bind(this)

    });
  }

  removeLastClasses() {
    this.removeClasses(this.state.lastAddedCourses);
    alert("That class(es) won't work with this schedule. If you tried to add multiple classes at once, you can try to add them one by one to see if any will work.");
    this.setState({lastAddedCourses: []});
  }

  addClasses(rows) {
    this.setState((prevState, props) => {
      var updatedCourses = prevState.renderedCourses;
      rows.every(function(rowIdx, tableLoop, rowLoop) {
        updatedCourses.add(this.data())
      });

      return {
        renderedCourses: updatedCourses,
        lastAddedCourses: rows
      }
    }, () => {
      this.requestClasses(Array.from(this.state.renderedCourses));
    });
  }

  removeClasses(rows) {
    this.setState((prevState, props) => {
      var updatedCourses = prevState.renderedCourses;

      if (rows.data().length < 1) {
        updatedCourses.clear();
      } else {
        rows.every(function(rowIdx, tableLoop, rowLoop) {
          updatedCourses.delete(this.data())
        });
      }

      return {renderedCourses: updatedCourses}
    }, () => {
      this.requestClasses(Array.from(this.state.renderedCourses));
    });
  }

  lastSched() {
    if (this.state.schedNumber > 0) {
      this.setState(prevState => ({
        schedNumber: prevState.schedNumber - 1
      }), () => {
        console.log(this.state.schedNumber);
      });
    }
  }

  nextSched() {
    if (this.state.schedNumber < this.state.schedCount - 1) {
      this.setState(prevState => ({
        schedNumber: prevState.schedNumber + 1
      }), () => {
        console.log(this.state.schedNumber);
      });
    }
  }

  render() {
    return (
      <div>
        <div id="calendar_row" className="row">
          <div className="small-12 large-9 columns">
            <Calendar events={this.state.schedule[this.state.schedNumber]}/>
            <div className='sched_button small-6 columns' onClick={this.lastSched}>BUTTON</div>
            <div className='sched_button small-6 columns' onClick={this.nextSched}>BUTTON 2</div>
          </div>
          <div id="filters" className="small-12 large-3 columns">
            <div className="small-6 columns">
              <input type="text" id="start_time" size="10" defaultValue="08:00" className="ui-timepicker-input" />
            </div>
            <div className="small-6 columns">
              <input type="text" id="end_time" size="10" defaultValue="19:00"  className="ui-timepicker-input"/>
            </div>
          </div>
        </div>

        <hr/>

        <div className="row">
          <div className="courses_table small-12 columns">
            <CourseSelector requestClassesFunction={this.requestClasses}
                            addClasses={this.addClasses}
                            removeClasses={this.removeClasses}
            />,
          </div>
        </div>
      </div>
    )
  }
}

class CourseSelector extends React.Component {
  constructor() {
    super();

    this.handleChange = this.handleChange.bind(this);
    this.state = {renderedCourses: new Set(), subjects: []};

    fetch('/subjects').then(function(result) {
      return result.json()
    }).then(function(result) {
      this.setState({subjects: result});
    }.bind(this));
  }

  componentDidMount() {
    var component = this;

    $('#class_list').DataTable({
      dom: 'Bfrtip',
      select: {
        style: 'os'
      },
      buttons: [
        {
          text: 'Add classes',
          action: function() {
            component.props.addClasses(this.rows({selected: true}))
          }
        },
        {
          text: 'Remove classes',
          action: function() {
            component.props.removeClasses(this.rows({selected: true}));
          }
        }
      ]
    });
  }

  handleChange(event) {
    this.setState({value: event.target.value});

    $('#class_list').DataTable().rows().remove(); // remove rows from last request
    fetch('/courses/' + event.target.value).then(function(result) {
      return result.json()
    }).then(function(courses) {
      $('#class_list').DataTable().rows.add(courses).draw();
    });
  }

  render() {
    return (
      <div>
        <select id="course_selector" onChange={this.handleChange}>
          {
            this.state.subjects.map(function(subject, i) {
              return (
                <option value={subject} key={i}>{subject}</option>
              )
            })
          }
        </select>

        <table id="class_list" className="display class_table">
          <thead>
            <tr>
              <th>Course Number</th>
              <th>Credit Hours</th>
              <th>Title</th>
            </tr>
          </thead>
        </table>
      </div>
    )
  }
}

class Calendar extends React.Component {
  componentDidMount() {
    $('#calendar').last_width = $(window).width();

    $('#calendar').fullCalendar({
      defaultView: 'agendaWeek',
      minTime: "8:00:00",
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
        callback(this.props.events)
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

$(document).ready(function() {
  ReactDOM.render(
    <ScheduleCalendar/>,
    document.getElementById('calendar_container')
  );
})
