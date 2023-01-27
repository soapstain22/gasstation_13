import { BooleanLike } from 'common/react';
import { useBackend } from '../backend';
import { Button, Table, NoticeBox } from '../components';
import { Window } from '../layouts';
import { ScrollableSection } from './LibraryConsole';

type Data = {
  server_connected: BooleanLike;
  servers: ServerData[];
  consoles: ConsoleData[];
  logs: LogData[];
};

type ServerData = {
  server_name: string;
  server_details: string;
  server_disabled: string;
};

type ConsoleData = {
  console_name: string;
  console_location: string;
  console_locked: string;
};

type LogData = {
  node_name: string;
  node_cost: string;
  node_researcher: string;
  node_research_location: string;
};

export const ServerControl = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { server_connected, servers, consoles, logs } = data;
  if (!server_connected) {
    return (
      <Window width={575} height={400}>
        <Window.Content>
          <NoticeBox textAlign="center" danger>
            Not connected to a Server. Please sync one using a multitool.
          </NoticeBox>
        </Window.Content>
      </Window>
    );
  }
  return (
    <Window width={575} height={400}>
      <Window.Content>
        {!servers.length ? (
          <NoticeBox mt={2} info>
            No servers found.
          </NoticeBox>
        ) : (
          <Table cellpadding="3" textAlign="center">
            <Table.Row header>
              <Table.Cell>Research Servers</Table.Cell>
            </Table.Row>
            {servers.map((server) => (
              <>
                <Table.Row header key={server} />
                <Table.Cell> {server.server_name}</Table.Cell>
                <Button
                  mt={1}
                  tooltip={server.server_details}
                  color={server.server_disabled ? 'good' : 'bad'}
                  content={server.server_disabled ? 'Online' : 'Offline'}
                  fluid
                  textAlign="center"
                />
              </>
            ))}
          </Table>
        )}

        {!consoles.length ? (
          <NoticeBox mt={2} info>
            No consoles found.
          </NoticeBox>
        ) : (
          <Table cellpadding="3" textAlign="center">
            <Table.Row header>
              <Table.Cell>Research Consoles</Table.Cell>
            </Table.Row>
            {consoles.map((console) => (
              <>
                <Table.Row header key={console} />
                <Table.Cell>
                  {' '}
                  {console.console_name} - Location: {console.console_location}{' '}
                </Table.Cell>
                <Button
                  mt={1}
                  color={console.console_locked ? 'good' : 'bad'}
                  content={console.console_locked ? 'Unlock' : 'Lock'}
                  fluid
                  textAlign="center"
                />
              </>
            ))}
          </Table>
        )}

        {!logs.length ? (
          <NoticeBox mt={2} info>
            No history found.
          </NoticeBox>
        ) : (
          <ScrollableSection
            header="Research History"
            contents={<ServerLogs />}
          />
        )}
      </Window.Content>
    </Window>
  );
};

const ServerLogs = (props, context) => {
  const { data } = useBackend<Data>(context);
  const { logs } = data;
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>Research Name</Table.Cell>
        <Table.Cell>Cost</Table.Cell>
        <Table.Cell>Researcher Name</Table.Cell>
        <Table.Cell>Console Location</Table.Cell>
      </Table.Row>
      {logs.map((server_log) => (
        <Table.Row mt={1} key={server_log.node_name}>
          <Table.Cell>{server_log.node_name}</Table.Cell>
          <Table.Cell>{server_log.node_cost}</Table.Cell>
          <Table.Cell>{server_log.node_researcher}</Table.Cell>
          <Table.Cell>{server_log.node_research_location}</Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};
