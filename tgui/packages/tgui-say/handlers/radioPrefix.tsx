import { RADIO_PREFIXES } from '../constants';
import { TguiModal } from '../types';

/**
 * Gets any channel prefixes from the chat bar
 * and changes to the corresponding radio subchannel.
 *
 * Exemptions: Channel is OOC, value is too short,
 * Not a valid radio pref, or value is already the radio pref.
 */
export const handleRadioPrefix = function (this: TguiModal) {
  const { channel } = this.state;
  const { radioPrefix, value } = this;
  if (channel > 1 || value.length < 3) {
    return;
  }
  const nextPrefix = value.slice(0, 3)?.toLowerCase();
  if (!RADIO_PREFIXES[nextPrefix] || radioPrefix === nextPrefix) {
    return;
  }
  this.value = value.slice(3);
  // Binary is a "secret" channel
  if (nextPrefix === ':b ') {
    Byond.sendMessage('thinking', { mode: false });
  } else if (radioPrefix === ':b ' && nextPrefix !== ':b ') {
    Byond.sendMessage('thinking', { mode: true });
  }
  this.radioPrefix = nextPrefix;
  this.setState({
    buttonContent: RADIO_PREFIXES[nextPrefix]?.label,
    channel: 0,
    edited: true,
  });
};
