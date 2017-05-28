import React from 'react';

export default class Filter extends React.Component {
  render() {
    return (
      <div className="filterBlock column column-block">
        <div className="card">
          <div className="card-divider">
            <h6>{this.props.filterType}</h6>
          </div>
          <div className="card-section">
            {this.props.children}
          </div>
        </div>
      </div>
    )
  }
}
