import { useBackend } from '../../backend';
import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { toFixed } from 'common/math';
import { ActNone, ActSet, HoverHelp, HelpDummy } from './helpers';

import { Box, Button, LabeledList, NumberInput, ProgressBar, Section, Tooltip } from '../../components';
import { getGasColor, getGasLabel } from '../../constants';

const moderator_gases_help = {
  plasma: "Produces basic gases. Has a modest heat bonus to help kick start the early fusion process. When added in large quantities, its high heat capacity can help to slow down temperature changes to manageable speeds.",
  bz: "Produces intermediate gases at Fusion Level 3 or higher. Massively increases radiation, and induces hallucinations in bystanders.",
  proto_nitrate: "Produces advanced gases. Massively increases radiation, and accelerates the rate of temperature change. Make sure you have enough cooling.",
  o2: "When added in high quantities, rapidly purges iron content. Does not purge iron content fast enough to keep up with damage at high Fusion Levels.",
  healium: "Directly heals a heavily damaged HFR core at high Fusion Levels, but is rapidly consumed in the process.",
  antinoblium: "Provides huge amounts of energy and radiation. Can cause dangerous electrical storms even from a healthy HFR core when present in more than trace amounts. Wear appropriate electrical protection when handling.",
  freon: "Saps most forms of energy expression. Slows the rate of temperature change.",
};

const moderator_gases_sticky_order = [
  "plasma",
  "bz",
  "proto_nitrate",
];

const ensure_gases = (gas_array, gasids) => {
  const gases_by_id = {};
  gas_array.forEach(gas => { gases_by_id[gas.id] = true; });

  for (let gasid of gasids) {
    if (!gases_by_id[gasid]) {
      gas_array.push({ id: gasid, amount: 0 });
    }
  }
};

const GasList = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    input_max,
    input_min,
    input_rate,
    input_switch,
    gases: raw_gases,
    minimumScale,
    prepend,
    rateHelp,
    stickyGases,
  } = props;

  const gases = flow([
    filter(gas => gas.amount >= 0.01),
    sortBy(gas => -gas.amount),
  ])(raw_gases || []);

  if (stickyGases) {
    ensure_gases(gases, stickyGases);
  }

  return (
    <LabeledList>
      <LabeledList.Item
        label={
          <>
            <HoverHelp content={rateHelp} />
            Injection Rate:
          </>
        }
      >
        <Button
          disabled={data.start_power === 0
              || data.start_cooling === 0}
          icon={data[input_switch] ? 'power-off' : 'times'}
          content={data[input_switch] ? 'On' : 'Off'}
          selected={data[input_switch]}
          onClick={ActNone(act, input_switch)} />
        <NumberInput
          animated
          value={parseFloat(data[input_rate])}
          unit="mol/s"
          minValue={input_min}
          maxValue={input_max}
          onDrag={ActSet(act, input_rate)}
        />
      </LabeledList.Item>
    {gases.map(gas => {
      let labelPrefix;
      if (prepend) {
        labelPrefix = prepend(gas)
      }
      return (
      <LabeledList.Item
        key={gas.id}
        label={
          <>
            (labelPrefix)
            {getGasLabel(gas.id)}:
          </>}
        >
        <ProgressBar
          color={getGasColor(gas.id)}
          value={gas.amount}
          minValue={0}
          maxValue={minimumScale}>
          {toFixed(gas.amount, 2) + ' moles'}
        </ProgressBar>
      </LabeledList.Item>);
    })}
  </LabeledList>);
};

export const HypertorusGases = props => {
  const {
    fusionGases: fusion_gases,
    moderatorGases: moderator_gases,
    selectedFuel,
  } = props;

  return (
    <>
      <Section title="Internal Fusion Gases">
        {selectedFuel 
          ? (
            <GasList
              input_rate="fuel_injection_rate"
              input_switch="start_fuel"
              input_max={150}
              input_min={.5}
              gases={fusion_gases}
              minimumScale={500}
              prepend={()=>(<HelpDummy />)}
              rateHelp={"The rate at which new fuel is added from the fuel input port. "
               + "Affects the rate of production, even when not active."}
              stickyGases={selectedFuel.requirements}
            />
          )
          : (
            <Box align="center" color="red">
              {"No recipe selected"}
            </Box>
          )}
      </Section>
      <Section title="Moderator Gases">
        <GasList
          input_rate="moderator_injection_rate"
          input_switch="start_moderator"
          input_max={150}
          input_min={.5}
          gases={moderator_gases}
          minimumScale={500}
          rateHelp={"The rate at which new moderator gas is added from the moderator port."}
          stickyGases={moderator_gases_sticky_order}
          prepend={gas=>
            moderator_gases_help[gas.id]
            ? (<HoverHelp content={moderator_gases_help[gas.id]} />)
            : (<HelpDummy />)
          }
        />
      </Section>
    </>
  );
};
