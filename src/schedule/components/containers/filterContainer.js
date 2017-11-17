import {
    connect
} from 'react-redux'
import {
    changeStartTime,
    changeEndTime,
    changeCreditHours,
    MIN_CREDIT_HOURS,
    MAX_CREDIT_HOURS
} from '../../reducers/courseFilters'
import Filters from '../filter'

const mapStateToProps = (state) => {
    return {
        minHours: state.courseFilters.creditHours.minHours,
        maxHours: state.courseFilters.creditHours.maxHours
    }
}

const mapDispatchToProps = (dispatch) => {
    return {
        changeStartTime: (newTime) => {
            dispatch(changeStartTime(newTime))
        },
        changeEndTime: (newTime) => {
            dispatch(changeEndTime(newTime))
        },
        changeCreditHours: (isSettingMinHours, event) => {
            if (parseInt(event.target.value) == NaN) {
                return
            }

            let newHours = parseInt(event.target.value)

            if (newHours < MIN_CREDIT_HOURS || newHours > MAX_CREDIT_HOURS) {
                return
            }

            console.log(event.target.value)
            dispatch(changeCreditHours(isSettingMinHours, newHours))
        }
    }
}

const FilterContainer = connect(
    mapStateToProps,
    mapDispatchToProps
)(Filters)

export default FilterContainer