import { useBackend } from '../../backend';
import { BlockQuote, Box, LabeledList, NoticeBox, Section, Stack } from '../../components';
import { RequestPriority, RequestsData } from './Types';

export const MessageViewTab = (props, context) => {
  const { act, data } = useBackend<RequestsData>(context);
  const { messages = [] } = data;
  return (
    <Section fill scrollable>
      {!!messages.length && (
        <Stack vertical>
          {messages.map((message) => (
            <MessageDisplay message={message} />
          ))}
        </Stack>
      )}
    </Section>
  );
};

export const MessageDisplay = (props, context) => {
  const { message } = props;
  const append_list_keys = message.appended_list
    ? Object.keys(message.appended_list)
    : [];
  return (
    <Stack.Item>
      <Section
        title={
          message.request_type +
          ' from ' +
          message.sender_department +
          ', ' +
          message.received_time
        }>
        {message.priority === RequestPriority.HIGH && (
          <NoticeBox warning>High Priority</NoticeBox>
        )}
        {message.priority === RequestPriority.EXTREME && (
          <NoticeBox bad>!!!Extreme Priority!!!</NoticeBox>
        )}
        <BlockQuote>
          {message.content}
          {!!message.appended_list && !!append_list_keys.length && (
            <LabeledList>
              {append_list_keys.map((list_key) => (
                <LabeledList.Item label={list_key}>
                  {message.appended_list[list_key]}
                </LabeledList.Item>
              ))}
            </LabeledList>
          )}
        </BlockQuote>
        <LabeledList>
          <LabeledList.Item label="Message Verified By">
            {message.message_verified_by || 'Not Verified'}
          </LabeledList.Item>
          <LabeledList.Item label="Message Stamped By">
            {message.message_stamped_by || 'Not Stamped'}
          </LabeledList.Item>
        </LabeledList>
      </Section>
    </Stack.Item>
  );
};
