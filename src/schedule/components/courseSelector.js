import React from 'react';

import {
    DataTable
} from 'datatables.net';
import {
    Button
} from 'datatables.net-buttons-zf';
import {
    Select
} from 'datatables.net-select';

export default class CourseSelector extends React.Component {
    constructor() {
        super();

        this.handleChange = this.handleChange.bind(this);
        this.state = {
            renderedCourses: new Set(),
            subjects: []
        };

        fetch('/subjects').then(function(result) {
            return result.json()
        }).then(function(result) {
            this.setState({
                subjects: result
            });
        }.bind(this));
    }

    componentDidMount() {
        var component = this;

        $('#class_list').DataTable({
            dom: 'Bfrtip',
            select: {
                style: 'os'
            },
            buttons: [{
                    text: 'Add classes',
                    action: function() {
                        component.props.addClasses(this.rows({
                            selected: true
                        }))
                    }
                },
                {
                    text: 'Remove classes',
                    action: function() {
                        component.props.removeClasses(this.rows({
                            selected: true
                        }));
                    }
                }
            ]
        });
    }

    handleChange(event) {
        this.setState({
            value: event.target.value
        });

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

        <table id="class_list" className="class_table display compact">
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