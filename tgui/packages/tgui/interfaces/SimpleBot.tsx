import { multiline } from '../../common/string';
import { useBackend } from '../backend';
import { Button, Icon, LabeledControls, NoticeBox, Section, Slider, Stack, Tooltip } from '../components';
import { Window } from '../layouts';

type SimpleBotContext = {
  can_hack: number;
  locked: number;
  emagged: number;
  pai: Pai;
  settings: Settings;
  custom_controls: Controls;
};

type Pai = {
  allow_pai: number;
  card_inserted: number;
};

type Settings = {
  power: number;
  airplane_mode: number;
  maintenance_lock: number;
  patrol_station?: number;
};

type Controls = {
  [Control: string]: [Value: number];
};

export const SimpleBot = (_, context) => {
  const { data } = useBackend<SimpleBotContext>(context);
  const { locked } = data;

  return (
    <Window width={600} height={300}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Settings" buttons={<TabDisplay />}>
              <SettingsDisplay />
            </Section>
          </Stack.Item>
          {!locked && (
            <Stack.Item grow>
              <Section fill scrollable title="Controls">
                <ControlsDisplay />
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

/** Creates a lock button at the top of the controls */
const TabDisplay = (_, context) => {
  const { act, data } = useBackend<SimpleBotContext>(context);
  const { can_hack, locked, pai } = data;
  const { allow_pai } = pai;

  return (
    <>
      {!!can_hack && <HackButton />}
      {!!allow_pai && <PaiButton />}
      <Button.Checkbox
        checked={locked}
        icon={locked ? 'lock' : 'lock-open'}
        onClick={() => act('lock')}
        tooltip={`${locked ? 'Unlock' : 'Lock'} the bot control panel.`}>
        Controls Lock
      </Button.Checkbox>
    </>
  );
};

/** If user is a bad silicon, they can press this button to hack the bot */
const HackButton = (_, context) => {
  const { act, data } = useBackend<SimpleBotContext>(context);
  const { emagged } = data;

  return (
    <Button.Checkbox
      icon="user-secret"
      onClick={() => act('hack')}
      selected={emagged}
      tooltip="Detects malware in the bot operating system.">
      {emagged ? "Malfunctional" : "Systems Nominal"}
    </Button.Checkbox>
  );

};

/** Creates a button indicating PAI status and offers the eject action */
const PaiButton = (_, context) => {
  const { act, data } = useBackend<SimpleBotContext>(context);
  const { card_inserted } = data.pai;

  if (!card_inserted) {
    return (
      <Button.Checkbox
        icon="robot"
        tooltip={multiline`Insert an active PAI card to control this device.`}>
        No PAI Inserted
      </Button.Checkbox>
    );
  } else {
    return (
      <Button.Confirm
        disabled={!card_inserted}
        icon="eject"
        onClick={() => act('eject_pai')}
        tooltip={multiline`Ejects the current PAI.`}>
        Eject PAI
      </Button.Confirm>
    );
  }
};

/** Displays the bot's standard settings: Power, patrol, etc. */
const SettingsDisplay = (_, context) => {
  const { act, data } = useBackend<SimpleBotContext>(context);
  const { locked, settings } = data;
  const { airplane_mode, patrol_station, power, maintenance_lock } = settings;
  if (locked) {
    return <NoticeBox>Locked!</NoticeBox>;
  }

  return (
    <LabeledControls>
      <LabeledControls.Item label="Power">
        <Tooltip content={`Powers ${power ? 'off' : 'on'} the bot.`}>
          <Icon
            size={2}
            name="power-off"
            color={power ? 'good' : 'gray'}
            onClick={() => act('power')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Airplane Mode">
        <Tooltip
          content={`${
            !airplane_mode ? 'Disables' : 'Enables'
          } remote access via console.`}>
          <Icon
            size={2}
            name="plane"
            color={airplane_mode ? 'yellow' : 'gray'}
            onClick={() => act('airplane')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Patrol Station">
        <Tooltip
          content={`${
            patrol_station ? 'Disables' : 'Enables'
          } automatic station patrol.`}>
          <Icon
            size={2}
            name="map-signs"
            color={patrol_station ? 'good' : 'gray'}
            onClick={() => act('patrol')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Maintenance Lock">
        <Tooltip
          content={
            maintenance_lock
              ? 'Opens the maintenance hatch for repairs.'
              : 'Closes the maintenance hatch.'
          }>
          <Icon
            size={2}
            name="toolbox"
            color={maintenance_lock ? 'yellow' : 'gray'}
            onClick={() => act('maintenance')}
          />
        </Tooltip>
      </LabeledControls.Item>
    </LabeledControls>
  );
};

/** Iterates over custom controls.
 * Calls the helper to identify which button to use.
 */
const ControlsDisplay = (_, context) => {
  const { data } = useBackend<SimpleBotContext>(context);
  const { custom_controls } = data;

  return (
    <LabeledControls>
      {Object.entries(custom_controls).map((control) => {
        return (
          <LabeledControls.Item
            key={control[0]}
            label={control[0]
              .replace('_', ' ')
              .replace(/(^\w{1})|(\s+\w{1})/g, (letter) =>
                letter.toUpperCase())}>
            <ControlHelper control={control} />
          </LabeledControls.Item>
        );
      })}
    </LabeledControls>
  );
};

/** Helper function which identifies which button to create.
 * Might need some fine tuning if you are using more advanced controls.
 */
const ControlHelper = (props, context) => {
  const { act } = useBackend<SimpleBotContext>(context);
  const { control } = props;
  if (control[0] === 'sync_tech') {
    /** Control is for sync - this is medbot specific */
    return <MedbotSync />;
  } else if (control[0] === 'heal_threshold') {
    /** Control is a threshold - this is medbot specific */
    return <MedbotThreshold control={control} />;
  } else {
    /** Control is a boolean of some type */
    return (
      <Icon
        color={control[1] ? 'good' : 'gray'}
        name={control[1] ? 'toggle-on' : 'toggle-off'}
        size={2}
        onClick={() => act(control[0])}
      />
    );
  }
};

/** Small button to sync medbots with research. */
const MedbotSync = (_, context) => {
  const { act } = useBackend<SimpleBotContext>(context);
  return (
    <Tooltip
      content={multiline`Synchronize surgical data with research network.
       Improves Tending Efficiency.`}>
      <Icon
        color="purple"
        name="cloud-download-alt"
        size={2}
        onClick={() => act('sync_tech')}
      />
    </Tooltip>
  );
};

/** Slider button for medbot healing thresholds */
const MedbotThreshold = (props, context) => {
  const { act } = useBackend<SimpleBotContext>(context);
  const { control } = props;

  return (
    <Tooltip content={multiline`Adjusts the sensitivity for damage treatment.`}>
      <Slider
        minValue={5}
        maxValue={75}
        ranges={{
          good: [-Infinity, 15],
          average: [15, 55],
          bad: [55, Infinity],
        }}
        step={5}
        unit="%"
        value={control[1]}
        onChange={(_, value) => act(control[0], { threshold: value })}
      />
    </Tooltip>
  );
};
