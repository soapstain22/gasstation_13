import { map, fastMap, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { clamp } from 'common/math';
import { vec } from 'common/vector';
import { Fragment } from 'inferno';
import { act } from '../byond';
import { Box, Button, Icon, LabeledList, Section, Table } from '../components';
import { createLogger } from '../logging';

const coordsToVec = coords => vec(fastMap(
  coords.split(', '),
  x => parseInt(x, 10)));

const logger = createLogger('Gps');

export const Gps = props => {
  const { state } = props;
  const { config, data } = state;
  const { ref } = config;
  const {
    currentArea,
    currentCoords,
    globalmode,
    power,
    tag,
    updating,
  } = data;
  logger.log(currentCoords, coordsToVec(currentCoords));
  const signals = flow([
    map(signal => {
      // Calculate distance to the target. BYOND distance is capped to 127,
      // that's why we roll our own calculations here.
      const dist = signal.dist && (
        Math.round(coordsToVec(currentCoords)
          .subtract(coordsToVec(signal.coords))
          .magnitude())
      );
      return { ...signal, dist };
    }),
    sortBy(
      // Signals with distance metric go first
      signal => signal.dist === undefined,
      // Sort alphabetically
      signal => signal.entrytag),
  ])(data.signals || []);
  return (
    <Fragment>
      <Section
        title="Control"
        buttons={(
          <Button
            icon="power-off"
            content={power ? "On" : "Off"}
            selected={power}
            onClick={() => act(ref, "power")}
          />
        )}>
        <LabeledList>
          <LabeledList.Item label="Tag">
            <Button
              icon="pencil-alt"
              content={tag}
              onClick={() => act(ref, "rename")}
            />
          </LabeledList.Item>
          <LabeledList.Item label="Scan Mode">
            <Button
              icon={updating ? "unlock" : "lock"}
              content={updating ? "AUTO" : "MANUAL"}
              color={!updating && "bad"}
              onClick={() => act(ref, "updating")}
            />
          </LabeledList.Item>
          <LabeledList.Item label="Range">
            <Button
              icon="sync"
              content={globalmode ? "MAXIMUM" : "LOCAL"}
              selected={!globalmode}
              onClick={() => act(ref, "globalmode")}
            />
          </LabeledList.Item>
        </LabeledList>
      </Section>
      {!!power && (
        <Fragment>
          <Section title="Current Location">
            <Box fontSize="18px">
              {currentArea} ({currentCoords})
            </Box>
          </Section>
          <Section title="Detected Signals">
            <Table>
              <Table.Row bold>
                <Table.Cell content="Name" />
                <Table.Cell collapsing content="Direction" />
                <Table.Cell collapsing content="Coordinates" />
              </Table.Row>
              {signals.map(signal => (
                <Table.Row
                  key={signal.entrytag + signal.coords}
                  className="candystripe">
                  <Table.Cell bold color="label">
                    {signal.entrytag}
                  </Table.Cell>
                  <Table.Cell
                    collapsing
                    opacity={signal.dist !== undefined && (
                      clamp(1.2 / Math.log(Math.E + signal.dist / 20), 0.4, 1)
                    )}>
                    {signal.degrees !== undefined && (
                      <Icon
                        mr={1}
                        size={1.2}
                        name="arrow-up"
                        rotation={signal.degrees} />
                    )}
                    {signal.dist !== undefined && (
                      signal.dist + 'm'
                    )}
                  </Table.Cell>
                  <Table.Cell collapsing>
                    {signal.coords}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        </Fragment>
      )}
    </Fragment>
  );
};
