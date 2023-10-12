import _ from 'lodash';

const SystemMode = {
  HOME: {
    id: 2,
    name: "home"
  },
  AWAY: {
    id: 3,
    name: "away"
  },
  SLEEP: {
    id: 5,
    name: "sleep"
  },
  UNKNOWN: {
    id: -1,
    name: "unknown"
  }
};

function fromName(name: string) {
  return _.values( _.pickBy(SystemMode, (value, _) => {
    return value.name == name;
  }))[0];
}

function fromId(id: number) {
  return _.values( _.pickBy(SystemMode, (value, _) => {
    return value.id == id;
  }))[0];
}

export default {
  ...SystemMode,
  fromName,
  fromId
};
