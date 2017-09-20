import React from 'react';
import { Filter } from './filter.js';

class InstructorFilter extends React.Component {
  render() {
    return (
      <Filter filterType="Instructors">
        {
          this.props.courses.map(function(course, i) {
            return (
              <div key={i}>
                <CourseInstructorList
                  courseName={course.name}
                  instructors={Array.from(course.instructors).map(function(instructorId) {
                    return this.props.instructors[instructorId]
                  }.bind(this))}
                  handleInstructorClick={this.props.handleInstructorClick}
                />
                <hr className="cell small-centered small-12" />
              </div>
            )
          }.bind(this))
        }
      </Filter>
    )
  }
}

class CourseInstructorList extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      showInstructors: false,
    };

    this.handleClick = this.handleClick.bind(this);
  }

  handleClick() {
    this.setState((prevState) => {
      return {showInstructors: !prevState.showInstructors}
    });
  }

  render() {
    if (this.state.showInstructors) {
      return (
        <div>
          <a onClick={this.handleClick}>{this.props.courseName}</a>
          {
            this.props.instructors.map(function(instructor, i) {
              return (
                <Instructor
                  key={i}
                  instructor={instructor}
                  handleClick={this.props.handleInstructorClick}
                />
              )
            }.bind(this))
          }
        </div>
      )
    } else {
      return (
        <div>
          <a onClick={this.handleClick}>{this.props.courseName}</a>
        </div>
      )
    }
  }
}

class Instructor extends React.Component {
  render() {
    var style= {};
    if (!this.props.instructor.active) {
      style = {"textDecoration": "line-through"}
    }

    return (
      <div>
        <a
          onClick={() => this.props.handleClick(this.props.instructor)}
          style={style}
        >
          {this.props.instructor.name}
        </a>
      </div>
    )
  }
}

export { InstructorFilter }
