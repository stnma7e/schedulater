import React from 'react';

export default class CourseLock extends React.Component {
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
