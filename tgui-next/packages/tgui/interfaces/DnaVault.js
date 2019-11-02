import { toFixed } from 'common/math';
import { decodeHtmlEntities } from 'common/string';
import { Fragment } from 'inferno';
import { act } from '../byond';
import { Box, Button, LabeledList, NumberInput, Section, Grid, ProgressBar } from '../components';
import { createLogger } from '../logging';
import { getGasLabel } from './common/atmos';
import { InterfaceLockNoticeBox } from './common/InterfaceLockNoticeBox';

export const DnaVault = props => {
  const { state } = props;
  const { config, data } = state;
  const { ref } = config;
  const {
    completed,
    used,
    choiceA,
    choiceB,
    dna,
    dna_max,
    plants,
    plants_max,
    animals,
    animals_max,
  } = data;
  return (
    <Fragment>
      <Section title="DNA Vault Database">
        <LabeledList>
          <LabeledList.Item label="Human DNA">
            <ProgressBar
              value={dna / dna_max}
              content={dna + " / " + dna_max + " Samples"}
            />
          </LabeledList.Item>
          <LabeledList.Item label="Plant DNA">
            <ProgressBar
              value={plants / plants_max}
              content={plants + " / " + plants_max + " Samples"}
            />
          </LabeledList.Item>
          <LabeledList.Item label="Animal DNA">
            <ProgressBar
              value={animals / animals}
              content={animals + " / " + animals_max + " Samples"}
            />
          </LabeledList.Item>
        </LabeledList>
      </Section>
      {!!(completed && !used) && (
        <Section title="Personal Gene Therapy">
          <Box
            bold
            textAlign="center"
            mb={1}
          >
            Applicable Gene Therapy Treatments
          </Box>
          <Grid width="100%">
            <Grid.Item width="50%">
              <Button
                fluid
                bold
                content={choiceA}
                textAlign="center"
                onClick={() => act(ref, "gene", {choice: choiceA})}
              />
            </Grid.Item>
            <Grid.Item width="50%">
              <Button
                fluid
                bold
                content={choiceB}
                textAlign="center"
                onClick={() => act(ref, "gene", {choice: choiceB})}
              />
            </Grid.Item>
          </Grid>
        </Section>
      )}
    </Fragment>
  );
};
