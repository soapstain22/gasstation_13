import { BooleanLike } from '../../common/react';
import { useBackend, useLocalState } from '../backend';
import { Section, Stack, Tabs, Button, BlockQuote } from '../components';
import { Window } from '../layouts';
import { ObjectivePrintout, Objective, ReplaceObjectivesButton } from './common/Objectives';

const hereticRed = {
  color: '#e03c3c',
};

const hereticBlue = {
  fontWeight: 'bold',
  color: '#2185d0',
};

const hereticPurple = {
  fontWeight: 'bold',
  color: '#bd54e0',
};

const hereticGreen = {
  fontWeight: 'bold',
  color: '#20b142',
};

const hereticYellow = {
  fontWeight: 'bold',
  color: 'yellow',
};

type Knowledge = {
  path: string;
  name: string;
  desc: string;
  gainFlavor: string;
  cost: number;
  disabled: boolean;
  hereticPath: string;
  color: string;
};

type KnowledgeInfo = {
  learnableKnowledge: Knowledge[];
  learnedKnowledge: Knowledge[];
};

type Info = {
  charges: number;
  side_charges: number;
  total_sacrifices: number;
  objectives: Objective[];
  can_change_objective: BooleanLike;
};

const IntroductionSection = (props, context) => {
  const { data, act } = useBackend<Info>(context);
  const { objectives, can_change_objective } = data;

  return (
    <Stack justify="space-evenly" height="100%" width="100%">
      <Stack.Item grow>
        <Section title="You are the Heretic!" fill fontSize="14px">
          <Stack vertical>
            <FlavorSection />
            <Stack.Divider />
            <GuideSection />
            <Stack.Divider />
            <InformationSection />
            <Stack.Divider />
            <Stack.Item>
              <ObjectivePrintout
                fill
                titleMessage={
                  'Research dark knowledge to fulfil your personal goal'
                }
                objectives={objectives}
                objectiveFollowup={
                  <ReplaceObjectivesButton
                    can_change_objective={can_change_objective}
                    button_title={'Change Discipline'}
                    button_colour={'red'}
                  />
                }
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const FlavorSection = () => {
  return (
    <Stack.Item>
      <Stack vertical textAlign="center" fontSize="14px">
        <Stack.Item>
          <i>
            Another day at a meaningless job. You feel a&nbsp;
            <span style={hereticBlue}>shimmer</span>
            &nbsp;around you, as a realization of something&nbsp;
            <span style={hereticRed}>strange</span>
            &nbsp;in the air unfolds. You look inwards and discover something
            that will change your life.
          </i>
        </Stack.Item>
        <Stack.Item>
          <b>
            The <span style={hereticPurple}>Gates of Mansus</span>
            &nbsp;open up to your mind.
          </b>
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
};

const GuideSection = () => {
  return (
    <Stack.Item>
      <Stack vertical fontSize="12px">
        <Stack.Item>
          - Find reality smashing&nbsp;
          <span style={hereticPurple}>influences</span>
          &nbsp;around the station invisible to the normal eye and&nbsp;
          <b>right click</b> on them to harvest them for&nbsp;
          <span style={hereticBlue}>knowledge points</span>. Tapping them makes
          them visible to all after a short time.
        </Stack.Item>
        <Stack.Item>
          - Use your&nbsp;
          <span style={hereticRed}>Living Heart action</span>
          &nbsp;to track down&nbsp;
          <span style={hereticRed}>sacrifice targets</span>, but be careful:
          Pulsing it will produce a heartbeat sound that nearby people may hear.
          This action is tied to your <b>heart</b> - if you lose it, you must
          complete a ritual to regain it.
        </Stack.Item>
        <Stack.Item>
          - Draw a&nbsp;
          <span style={hereticGreen}>transmutation rune</span> by using a
          drawing tool (a pen or crayon) on the floor while having&nbsp;
          <span style={hereticGreen}>Mansus Grasp</span>
          &nbsp;active in your other hand. This rune allows you to complete
          rituals and sacrifices.
        </Stack.Item>
        <Stack.Item>
          - Follow your <span style={hereticRed}>Living Heart</span> to find
          your targets. Bring them back to a&nbsp;
          <span style={hereticGreen}>transmutation rune</span> in critical or
          worse condition to&nbsp;
          <span style={hereticRed}>sacrifice</span> them for&nbsp;
          <span style={hereticBlue}>knowledge points</span>. The Mansus{' '}
          <b>ONLY</b> accepts targets pointed to by the&nbsp;
          <span style={hereticRed}>Living Heart</span>.
        </Stack.Item>
        <Stack.Item>
          - Make yourself a <span style={hereticYellow}>focus</span> to be able
          to cast various advanced spells to assist you in acquiring harder and
          harder sacrifices.
        </Stack.Item>
        <Stack.Item>
          - Use the knowledge and power you gain to accomplish your goals!
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
};

const InformationSection = (props, context) => {
  const { data } = useBackend<Info>(context);
  const { charges, side_charges, total_sacrifices } = data;
  return (
    <Stack.Item>
      <Stack vertical fill>
        <Stack.Item>
          You have <b>{charges || 0}</b>&nbsp;
          <span style={hereticBlue}>
            knowledge point{charges !== 1 ? 's' : ''}
          </span>
          {!!side_charges && (
            <span>
              {' '}
              and <b>{side_charges}</b> side point
              {side_charges !== 1 ? 's' : ''}
            </span>
          )}{' '}
          .
        </Stack.Item>
        <Stack.Item>
          You have made a total of&nbsp;
          <b>{total_sacrifices || 0}</b>&nbsp;
          <span style={hereticRed}>sacrifices</span>.
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
};

const ResearchedKnowledge = (props, context) => {
  const { data } = useBackend<KnowledgeInfo>(context);
  const { learnedKnowledge } = data;

  return (
    <Stack.Item grow>
      <Section title="Researched Knowledge" fill scrollable>
        <Stack vertical>
          {(!learnedKnowledge.length && 'None!') ||
            learnedKnowledge.map((learned) => (
              <Stack.Item key={learned.name}>
                <Button
                  width="100%"
                  color={learned.color}
                  content={`${learned.hereticPath} - ${learned.name}`}
                  tooltip={learned.desc}
                />
              </Stack.Item>
            ))}
        </Stack>
      </Section>
    </Stack.Item>
  );
};

const KnowledgeShop = (props, context) => {
  const { data, act } = useBackend<KnowledgeInfo>(context);
  const { learnableKnowledge } = data;

  return (
    <Stack.Item grow>
      <Section title="Potential Knowledge" fill scrollable>
        {(!learnableKnowledge.length && 'None!') ||
          learnableKnowledge.map((toLearn) => (
            <Stack.Item key={toLearn.name} mb={1}>
              <Button
                width="100%"
                color={toLearn.color}
                disabled={toLearn.disabled}
                content={`${toLearn.hereticPath} - ${
                  toLearn.cost > 0
                    ? `${toLearn.name}: ${toLearn.cost}
                  point${toLearn.cost !== 1 ? 's' : ''}`
                    : toLearn.name
                }`}
                tooltip={toLearn.desc}
                onClick={() => act('research', { path: toLearn.path })}
              />
              {!!toLearn.gainFlavor && (
                <BlockQuote>
                  <i>{toLearn.gainFlavor}</i>
                </BlockQuote>
              )}
            </Stack.Item>
          ))}
      </Section>
    </Stack.Item>
  );
};

const ResearchInfo = (props, context) => {
  const { data } = useBackend<Info>(context);
  const { charges, side_charges } = data;

  return (
    <Stack justify="space-evenly" height="100%" width="100%">
      <Stack.Item grow>
        <Stack vertical height="100%">
          <Stack.Item fontSize="20px" textAlign="center">
            You have <b>{charges || 0}</b>&nbsp;
            <span style={hereticBlue}>
              knowledge point{charges !== 1 ? 's' : ''}
            </span>
            {!!side_charges && (
              <span>
                {' '}
                and <b>{side_charges}</b> side point
                {side_charges !== 1 ? 's' : ''}
              </span>
            )}{' '}
            to spend.
          </Stack.Item>
          <Stack.Item grow>
            <Stack height="100%">
              <ResearchedKnowledge />
              <KnowledgeShop />
            </Stack>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

export const AntagInfoHeretic = (props, context) => {
  const { data } = useBackend<Info>(context);

  const [currentTab, setTab] = useLocalState(context, 'currentTab', 0);

  return (
    <Window width={675} height={635}>
      <Window.Content
        style={{
          'background-image': 'none',
          'background':
            'radial-gradient(circle, rgba(9,9,24,1) 54%, rgba(10,10,31,1) 60%, rgba(21,11,46,1) 80%, rgba(24,14,47,1) 100%);',
        }}>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="info"
                selected={currentTab === 0}
                onClick={() => setTab(0)}>
                Information
              </Tabs.Tab>
              <Tabs.Tab
                icon={currentTab === 1 ? 'book-open' : 'book'}
                selected={currentTab === 1}
                onClick={() => setTab(1)}>
                Research
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {(currentTab === 0 && <IntroductionSection />) || <ResearchInfo />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
