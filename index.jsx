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
    this.state = {schedNumber: 0, schedCount: 0, schedule: []};

    this.nextSched = this.nextSched.bind(this);
    this.lastSched = this.lastSched.bind(this);
    this.getSched  = this.getSched.bind(this);
    this.requestClasses  = this.requestClasses.bind(this);
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

  getSched() {
    console.log(this.state);
    $.ajax({
      url:'/courses',
      type: "POST",
      data: JSON.stringify(this.state.courseRequest),
      success: function(result) {
        var courses = JSON.parse(result);
        var schedList = courses.schedule;
        this.setState({
          schedCount: courses.sched_count,
          schedule:   courses.schedule
        });

        $('#calendar').fullCalendar('refetchEvents');
      }.bind(this)
    });

  }

  requestClasses() {
      var table = $('#selected_classes').DataTable();
      var rows = table.data();
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

      console.log(titles);
      this.setState({
        courseRequest: {
          courses: titles,
          filters: [times]
        }
      });
      this.getSched();
  }

  lastSched() {
    if (this.state.schedNumber > 0) {
      this.setState(prevState => ({
        schedNumber: prevState.schedNumber - 1
      }), () => {
        console.log(this.state.schedNumber);
        $('#calendar').fullCalendar('refetchEvents');
      });
    }

  }

  nextSched() {
    if (this.state.schedNumber < this.state.schedCount - 1) {
      this.setState(prevState => ({
        schedNumber: prevState.schedNumber + 1
    }), () => {
        console.log(this.state.schedNumber);
        $('#calendar').fullCalendar('refetchEvents');
      });
    }
  }

  render() {
    return (
      <div>
        <div className="row">
          <div className="small-12 large-9 columns">
            <Calendar events={this.state.schedule[this.state.schedNumber]}/>
          </div>
          <div className="small-12 large-3 columns">
            <div className='sched_button' onClick={this.lastSched}>BUTTON</div>
            <div className='sched_button' onClick={this.nextSched}>BUTTON 2</div>

            <div className="row" id="filters">
              <div className="small-6 columns">
                <input type="text" id="start_time" size="10" defaultValue="08:00" className="ui-timepicker-input" />
              </div>
              <div className="small-6 columns">
                <input type="text" id="end_time" size="10" defaultValue="19:00"  className="ui-timepicker-input"/>
              </div>
            </div>
          </div>
        </div>

        <div className="row">
          <div id="selected_courses_column" className="small-12 large-4 columns">
            <SelectedCourses sendClassesFunction={this.requestClasses} />
          </div>
          <div id="course_list_column" className="small-12 large-8 columns">
            <CourseSelector/>,
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
    this.state = {subjects: []};

    fetch('/subjects').then(function(result) {
      return result.json()
    }).then(function(result) {
      this.setState({subjects: result});
    }.bind(this));

  }

  componentDidMount() {
    $('#class_list').DataTable({
      dom: 'Bfrtip',
      select: {
        style: 'os'
      },
      buttons: [
        {
          text: 'Add classes',
          action: function() {
            this.rows({ selected: true }).every(function(rowIdx, tableLoop, rowLoop) {
                $("#selected_classes").DataTable().row.add(this.data()).draw();
            });
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

class SelectedCourses extends React.Component {
  componentDidMount() {
    $("#selected_classes").DataTable({
      dom: 'Bfrtip',
      select: {
        style: 'os'
      },
      buttons : [
        {
          text: 'Remove classes',
          action: function() {
            $('#selected_classes').DataTable().rows({ selected: true }).remove().draw();
          }
        },
        {
          text: 'Send classes',
          action: this.props.sendClassesFunction
        }
      ]
    });
  }

  render() {
    return (
      <table id='selected_classes' className='display class_table'>
        <thead>
          <tr>
            <th>Course Number</th>
            <th>Credit Hours</th>
            <th>Title</th>
          </tr>
        </thead>
        <tbody>
        </tbody>
      </table>
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
}

$(document).ready(function() {
  ReactDOM.render(
    <ScheduleCalendar />,
    document.getElementById('calendar_container')
  );
})
