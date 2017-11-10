import React from 'react';

import CourseLock from './courseLock';

export default class CourseList extends React.Component {
  render() {
    return (
        <div className="cell grid-x grid-padding-x small-up-3 large-up-6">
            {this.props.classes.map((c, i) => {
              return (
                <CourseLock key={i}
                    courseIndex={i}
                    course={c}
                    lockedIn={this.props.lockedIn}
                    onClick={(selected) => {
                        if (selected) {
                            this.props.setSelectedCourse(i)
                        } else {
                            this.props.setSelectedCourse(null)
                        }
                    }}
                />
              )
            })}
        </div>
    )
  }
}
