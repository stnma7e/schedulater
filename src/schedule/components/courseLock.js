import React from 'react';
import PropTypes from 'prop-types';

import { FlatCourse } from '../../common'

export default class CourseLock extends React.Component {
  constructor() {
      super()
  }
  render() {
    return (
      <div className="cell grid-y courseHolder"
        style={{
          "display": "flex",
          "alignItems": "center",
          "justifyContent": "center",
        }}
        onClick={this.props.onClick}
      >
        {this.props.course.title}, {function() {
            if (this.props.lockedIn[this.props.courseIndex] > 0) {
              return (
                this.props.course.classes[this.props.lockedIn[this.props.courseIndex] - 1]
                  .map((thisClass) => {
                    return (
                      <AltClass
                        key={thisClass.crn}
                        crn={thisClass.crn}
                        instructor={thisClass.instructor}
                      />
                    )
                  })
              )
            } else {
              return "None locked in"
            }
          }.bind(this)()
        }
      </div>
    )
  }
}

CourseLock.propTypes = {
    courseIndex: PropTypes.number,
    course:      PropTypes.instanceOf(FlatCourse),
    lockedIn:    PropTypes.arrayOf(PropTypes.number)
}

class AltClass extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      showClass: false,
    };

    this.handleClick = this.handleClick.bind(this);
  }

  handleClick() {
    this.setState((prevState) => {
      return {showClass: !prevState.showClass}
    });
  }

  render() {
    if (this.state.showClass) {
      return (
        <div>
          <a onClick={this.handleClick}>{this.props.crn}</a>
        </div>
      )
    } else {
      return (
        <div>
          <a onClick={this.handleClick}>{this.props.instructor}</a>
        </div>
      )
    }
  }
}

AltClass.propTypes = {
    crn:        PropTypes.number,
    instructor: PropTypes.string
}
