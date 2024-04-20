import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { createSearch } from 'common/string';
import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, Input, Section, Table } from '../components';
import { COLORS } from '../constants';
import { Window } from '../layouts';

const HEALTH_COLOR_BY_LEVEL = [
  '#17d568',
  '#c4cf2d',
  '#e67e22',
  '#ed5100',
  '#e74c3c',
  '#801308',
];

const STAT_LIVING = 0;
const STAT_DEAD = 4;

const jobIsHead = (jobId) => jobId % 10 === 0;

const jobToColor = (jobId) => {
  if (jobId === 0) {
    return COLORS.department.captain;
  }
  if (jobId >= 10 && jobId < 20) {
    return COLORS.department.security;
  }
  if (jobId >= 20 && jobId < 30) {
    return COLORS.department.medbay;
  }
  if (jobId >= 30 && jobId < 40) {
    return COLORS.department.science;
  }
  if (jobId >= 40 && jobId < 50) {
    return COLORS.department.engineering;
  }
  if (jobId >= 50 && jobId < 60) {
    return COLORS.department.cargo;
  }
  if (jobId >= 60 && jobId < 200) {
    return COLORS.department.service;
  }
  if (jobId >= 200 && jobId < 230) {
    return COLORS.department.centcom;
  }
  return COLORS.department.other;
};

const statToIcon = (life_status) => {
  switch (life_status) {
    case STAT_LIVING:
      return 'heart';
    case STAT_DEAD:
      return 'skull';
  }
  return 'heartbeat';
};

const healthToAttribute = (oxy, tox, burn, brute, attributeList) => {
  const healthSum = oxy + tox + burn + brute;
  const level = Math.min(Math.max(Math.ceil(healthSum / 25), 0), 5);
  return attributeList[level];
};

const HealthStat = (props) => {
  const { type, value } = props;
  return (
    <Box inline width={2} color={COLORS.damageType[type]} textAlign="center">
      {value}
    </Box>
  );
};

export const CrewConsole = () => {
  return (
    <Window title="Crew Monitor" width={600} height={600}>
      <Window.Content scrollable>
        <Section minHeight="540px">
          <CrewTable />
        </Section>
      </Window.Content>
    </Window>
  );
};

const CrewTable = (props) => {
  const { act, data } = useBackend();
  const sensors = data.sensors;

  const [shownSensors, setShownSensors] = useState(sensors.slice());
  const [sortAsc, setSortAsc] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortColumns, setSortColumns] = useState(['ijob', 'health', 'area']);

  const sortNames = {
    ijob: 'Job',
    name: 'Name',
    area: 'Position',
    health: 'Vitals',
  };

  const cycleSortMode = () => {
    let newColumns = sortColumns.slice();
    newColumns.push(newColumns.shift());
    setSortColumns(newColumns);
  };

  const healthSort = (a, b) => {
    if (a.life_status < b.life_status) return -1;
    if (a.life_status > b.life_status) return 1;
    if (a.health > b.health) return -1;
    if (a.health < b.health) return 1;
    return 0;
  };

  useEffect(() => {
    let unsorted = sensors.slice();
    if (sortColumns[0] === 'ijob') {
      let sorted = flow([
        (sorted) => {
          return sortBy(data.sensors, (s) => s.ijob);
        },
        (sorted) => {
          const nameSearch = createSearch(searchQuery, (crew) => crew.name);
          return filter(sorted, nameSearch);
        },
      ])();
      if (!sortAsc) {
        sorted.reverse();
      }
      setShownSensors(sorted);
      return;
    } else if (sortColumns[0] === 'health') {
      unsorted.sort(healthSort);
    } else {
      unsorted.sort((a, b) => {
        a[sortColumns[0]] ??= '~';
        b[sortColumns[0]] ??= '~';
        if (a[sortColumns[0]] < b[sortColumns[0]]) return -1;
        if (a[sortColumns[0]] > b[sortColumns[0]]) return 1;
        return 0;
      });
    }

    let sorted = unsorted.filter(
      createSearch(searchQuery, (crew) => crew.name),
    );
    if (!sortAsc) {
      sorted.reverse();
    }
    setShownSensors(sorted);
  }, [searchQuery, sensors, sortColumns, sortAsc]);

  return (
    <Section
      scrollable
      title={
        <>
          <Button onClick={() => cycleSortMode()}>
            {sortNames[sortColumns[0]] || sortColumns[0]}
          </Button>
          <Button onClick={() => setSortAsc(!sortAsc)}>
            <Icon
              style={{ marginLeft: '2px' }}
              name={sortAsc ? 'chevron-up' : 'chevron-down'}
            />
          </Button>
          <Input
            placeholder="Search for name..."
            onInput={(e) => setSearchQuery(e.target.value)}
          />
        </>
      }
    >
      <Table>
        <Table.Row>
          <Table.Cell bold>Name</Table.Cell>
          <Table.Cell bold collapsing />
          <Table.Cell bold collapsing textAlign="center">
            Vitals
          </Table.Cell>
          <Table.Cell bold textAlign="center">
            Position
          </Table.Cell>
          {!!data.link_allowed && (
            <Table.Cell bold collapsing textAlign="center">
              Tracking
            </Table.Cell>
          )}
        </Table.Row>
        {shownSensors.map((sensor) => (
          <CrewTableEntry sensor_data={sensor} key={sensor.ref} />
        ))}
      </Table>
    </Section>
  );
};

const CrewTableEntry = (props) => {
  const { act, data } = useBackend();
  const { link_allowed } = data;
  const { sensor_data } = props;
  const {
    name,
    assignment,
    ijob,
    life_status,
    oxydam,
    toxdam,
    burndam,
    brutedam,
    area,
    can_track,
  } = sensor_data;

  return (
    <Table.Row className="candystripe">
      <Table.Cell bold={jobIsHead(ijob)} color={jobToColor(ijob)}>
        {name}
        {assignment !== undefined ? ` (${assignment})` : ''}
      </Table.Cell>
      <Table.Cell collapsing textAlign="center">
        {oxydam !== undefined ? (
          <Icon
            name={statToIcon(life_status)}
            color={healthToAttribute(
              oxydam,
              toxdam,
              burndam,
              brutedam,
              HEALTH_COLOR_BY_LEVEL,
            )}
            size={1}
          />
        ) : life_status !== STAT_DEAD ? (
          <Icon name="heart" color="#17d568" size={1} />
        ) : (
          <Icon name="skull" color="#801308" size={1} />
        )}
      </Table.Cell>
      <Table.Cell collapsing textAlign="center">
        {oxydam !== undefined ? (
          <Box inline>
            <HealthStat type="oxy" value={oxydam} />
            {'/'}
            <HealthStat type="toxin" value={toxdam} />
            {'/'}
            <HealthStat type="burn" value={burndam} />
            {'/'}
            <HealthStat type="brute" value={brutedam} />
          </Box>
        ) : life_status !== STAT_DEAD ? (
          'Alive'
        ) : (
          'Dead'
        )}
      </Table.Cell>
      <Table.Cell>
        {area !== '~' && area !== undefined ? (
          area
        ) : (
          <Icon name="question" color="#ffffff" size={1} />
        )}
      </Table.Cell>
      {!!link_allowed && (
        <Table.Cell collapsing>
          <Button
            content="Track"
            disabled={!can_track}
            onClick={() =>
              act('select_person', {
                name: name,
              })
            }
          />
        </Table.Cell>
      )}
    </Table.Row>
  );
};
