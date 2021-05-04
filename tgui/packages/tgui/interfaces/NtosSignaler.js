import { SignalerContent } from './Signaler';
import { NtosWindow } from '../layouts';

export const NtosSignaler = (props, context) => {
  return (
    <NtosWindow
      width={800}
      height={600}>
      <NtosWindow.Content scrollable>
        <SignalerContent />
      </NtosWindow.Content>
    </NtosWindow>
  );
};
