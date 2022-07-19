/**
 * @license MIT
 */

import { classes } from 'common/react';
import { useBackend, useLocalState } from '../backend';
import { Button, Box, Flex, Section, TextArea } from '../components';
import { Window } from '../layouts';
import { sanitizeText } from '../sanitize';
import { marked } from 'marked';
import { Component, createRef, RefObject } from 'inferno';
import { clamp } from 'common/math';
import { logger } from '../logging';

const Z_INDEX_STAMP = 1;
const Z_INDEX_STAMP_PREVIEW = 2;

const TEXTAREA_INPUT_HEIGHT = 200;

type PaperContext = {
  // ui_static_data
  user_name: string;
  raw_text_input?: PaperInput[];
  raw_field_input?: FieldInput[];
  raw_stamp_input?: StampInput[];
  max_length: number;
  max_input_field_length: number;
  paper_color: string;
  paper_name: string;
  default_pen_font: string;
  default_pen_color: string;
  signature_font: string;

  // ui_data
  held_item_details?: WritingImplement;
};

type PaperInput = {
  raw_text: string;
  font?: string;
  color?: string;
  bold?: boolean;
};

type StampInput = {
  class: string;
  x: number;
  y: number;
  rotation: number;
};

type FieldInput = {
  field_index: string;
  field_data: PaperInput;
  is_signature: boolean;
};

type WritingImplement = {
  interaction_mode: InteractionType;
  font?: string;
  color?: string;
  use_bold?: boolean;
  stamp_icon_state?: string;
  stamp_class?: string;
};

type PaperSheetStamperState = {
  x: number;
  y: number;
  rotation: number;
  yOffset: number;
};

type PaperSheetStamperProps = {
  scrollableRef: RefObject<HTMLDivElement>;
};

enum InteractionType {
  reading = 0,
  writing = 1,
  stamping = 2,
}

const canEdit = (heldItemDetails?: WritingImplement): boolean => {
  if (!heldItemDetails) {
    return false;
  }

  return heldItemDetails.interaction_mode === InteractionType.writing;
};

const canStamp = (heldItemDetails?: WritingImplement): boolean => {
  if (!heldItemDetails) {
    return false;
  }

  return heldItemDetails.interaction_mode === InteractionType.stamping;
};

// This creates the html from marked text as well as the form fields
const createPreview = (
  inputList: PaperInput[] | undefined,
  fieldDataList: FieldInput[] | undefined,
  textAreaText: string | null,
  defaultFont: string,
  defaultColor: string,
  paperColor: string,
  heldItemDetails: WritingImplement | undefined
) => {
  let output = '';

  const readOnly = !canEdit(heldItemDetails);

  const heldColor = heldItemDetails?.color;
  const heldFont = heldItemDetails?.font;
  const heldBold = heldItemDetails?.use_bold;

  let fieldCounter = 0;

  inputList?.forEach((value) => {
    let rawText = value.raw_text.trim();
    if (!rawText.length) {
      return;
    }

    const fontColor = value.color || defaultColor;
    const fontFace = value.font || defaultFont;
    const fontBold = value.bold || false;

    let processingOutput = formatAndProcessRawText(
      rawText,
      fontFace,
      fontColor,
      fontBold,
      fieldCounter,
      readOnly
    );

    output += processingOutput.text;

    fieldCounter = processingOutput.fieldCount;
  });

  if (textAreaText?.length) {
    const fontColor = heldColor || defaultColor;
    const fontFace = heldFont || defaultFont;
    const fontBold = heldBold || false;

    output += formatAndProcessRawText(
      textAreaText,
      fontFace,
      fontColor,
      fontBold,
      fieldCounter,
      true
    ).text;
  }

  fillAllFields(fieldDataList || [], paperColor);

  return output;
};

const createIDHeader = (index) => {
  return 'paperfield_' + index;
};

const getHeaderID = (header) => {
  return header.replace('paperfield_', '');
};

// Hacky, yes, works?...yes
const textWidth = (text, font, fontsize) => {
  // default font height is 12 in tgui
  const c = document.createElement('canvas');
  const ctx = c.getContext('2d');
  ctx.font = `${fontsize}px ${font}`;
  return ctx.measureText(text).width;
};

const field_regex = /\[((?:_+))\]/gi;
const field_tag_regex =
  /\[<input\s+(?!disabled)(.*?)\s+id="paperfield_(?<id>\d+)"(.*?)\/>\]/gm;

const createFields = (
  txt,
  font,
  fontsize,
  color,
  forceReadonlyFields,
  counter = 0
) => {
  const ret_text = txt.replace(field_regex, (match, p1, offset, string) => {
    const width = textWidth(match, font, fontsize) + 'px';
    return createInputField(
      p1.length,
      width,
      font,
      fontsize,
      color,
      createIDHeader(counter++),
      forceReadonlyFields
    );
  });

  return {
    counter,
    text: ret_text,
  };
};

const createInputField = (
  length,
  width,
  font,
  fontsize,
  color,
  id,
  readOnly
) => {
  return `[<input ${
    readOnly ? 'disabled ' : ''
  }type="text" style="font-size:${fontsize}px; font-family: ${font};color:${color};min-width:${width};max-width:${width}" id="${id}" maxlength=${length} size=${length} />]`;
};

const formatAndProcessRawText = (
  text,
  font,
  color,
  bold,
  fieldCounter = 0,
  forceReadonlyFields = false
): { text: string; fieldCount: number } => {
  // First lets make sure it ends in a new line
  text += text[text.length] === '\n' ? '\n' : '\n\n';
  // Second, we sanitize the text of html
  const sanitizedText = sanitizeText(text);
  // const signed_text = signDocument(sanitized_text, color, user_name);

  // Third we replace the [__] with fields as markedjs fucks them up
  const fieldedText = createFields(
    sanitizedText,
    font,
    12,
    color,
    forceReadonlyFields,
    fieldCounter
  );

  // Fourth, parse the text using markup
  const parsedText = runMarkedDefault(fieldedText.text);

  // Fifth, we wrap the created text in the pin color, and font.
  // crayon is bold (<b> tags), maybe make fountain pin italic?
  const fontedText = setFontinText(parsedText, font, color, bold);

  return { text: fontedText, fieldCount: fieldedText.counter };
};

const setFontinText = (text, font, color, bold = false) => {
  return (
    '<span style="' +
    'color:' +
    color +
    ';' +
    "font-family:'" +
    font +
    "';" +
    (bold ? 'font-weight: bold;' : '') +
    '">' +
    text +
    '</span>'
  );
};

const runMarkedDefault = (value) => {
  // Override function, any links and images should
  // kill any other marked tokens we don't want here
  const walkTokens = (token) => {
    switch (token.type) {
      case 'url':
      case 'autolink':
      case 'reflink':
      case 'link':
      case 'image':
        token.type = 'text';
        // Once asset system is up change to some default image
        // or rewrite for icon images
        token.href = '';
        break;
    }
  };
  return marked(value, {
    breaks: true,
    smartypants: true,
    smartLists: true,
    walkTokens,
    // Once assets are fixed might need to change this for them
    baseUrl: 'thisshouldbreakhttp',
  });
};

const pauseEvent = (e) => {
  if (e.stopPropagation) {
    e.stopPropagation();
  }
  if (e.preventDefault) {
    e.preventDefault();
  }
  e.cancelBubble = true;
  e.returnValue = false;
  return false;
};

// again, need the states for dragging and such
class PaperSheetStamper extends Component<PaperSheetStamperProps> {
  style: null;
  handleMouseMove: (this: Document, ev: MouseEvent) => any;
  handleMouseClick: (this: Document, ev: MouseEvent) => any;
  state: PaperSheetStamperState = { x: 0, y: 0, rotation: 0, yOffset: 0 };
  scrollableRef: RefObject<HTMLDivElement>;

  constructor(props, context) {
    super(props, context);

    this.style = null;
    this.scrollableRef = props.scrollableRef;

    this.handleMouseMove = (e) => {
      const pos = this.findStampPosition(e);
      if (!pos) {
        return;
      }

      pauseEvent(e);
      this.setState({
        x: pos[0],
        y: pos[1],
        rotation: pos[2],
        yOffset: pos[3],
      });
    };

    this.handleMouseClick = (e) => {
      if (e.pageY <= 30) {
        return;
      }
      const { act } = useBackend<PaperContext>(this.context);

      act('add_stamp', {
        x: this.state.x,
        y: this.state.y + this.state.yOffset,
        rotation: this.state.rotation,
      });
    };
  }

  findStampPosition(e) {
    let rotating;
    const scrollable = this.scrollableRef.current;

    if (!scrollable) {
      return;
    }

    const stampYOffset = scrollable.scrollTop || 0;

    const stamp = document.getElementById('stamp');
    if (!stamp) {
      return;
    }

    if (e.shiftKey) {
      rotating = true;
    }

    const stampHeight = stamp.clientHeight;
    const stampWidth = stamp.clientWidth;

    const currentHeight = rotating ? this.state.y : e.pageY - stampHeight;
    const currentWidth = rotating ? this.state.x : e.pageX - stampWidth / 2;

    const widthMin = 0;
    const heightMin = 0;

    const widthMax = scrollable.clientWidth - stampWidth;
    const heightMax = scrollable.clientHeight - stampHeight;

    const radians = Math.atan2(
      currentWidth + stampWidth / 2 - e.pageX,
      currentHeight + stampHeight / 2 - e.pageY
    );

    const rotate = rotating
      ? radians * (180 / Math.PI) * -1
      : this.state.rotation;

    const pos = [
      clamp(currentWidth, widthMin, widthMax),
      clamp(currentHeight, heightMin, heightMax),
      rotate,
      stampYOffset,
    ];

    return pos;
  }

  componentDidMount() {
    document.addEventListener('mousemove', this.handleMouseMove);
    document.addEventListener('click', this.handleMouseClick);
  }

  componentWillUnmount() {
    document.removeEventListener('mousemove', this.handleMouseMove);
    document.removeEventListener('click', this.handleMouseClick);
  }

  render() {
    const { data } = useBackend<PaperContext>(this.context);
    const { held_item_details } = data;

    if (!held_item_details?.stamp_class) {
      return;
    }

    return (
      <Stamp
        activeStamp
        opacity={0.5}
        sprite={held_item_details.stamp_class}
        x={this.state.x}
        y={this.state.y}
        rotation={this.state.rotation}
      />
    );
  }
}

export const Stamp = (props, context) => {
  const { activeStamp, sprite, x, y, rotation, opacity, yOffset = 0 } = props;
  const stamp_transform = {
    'left': x + 'px',
    'top': y + yOffset + 'px',
    'transform': 'rotate(' + rotation + 'deg)',
    'opacity': opacity || 1.0,
    'z-index': activeStamp ? Z_INDEX_STAMP_PREVIEW : Z_INDEX_STAMP,
  };

  return (
    <div
      id="stamp"
      className={classes(['Paper__Stamp', sprite])}
      style={stamp_transform}
    />
  );
};

const hookAllFields = (raw_text, onInputHandler) => {
  let match;

  while ((match = field_tag_regex.exec(raw_text)) !== null) {
    const id = parseInt(match.groups.id, 10);

    if (!isNaN(id)) {
      const dom = document.getElementById(
        createIDHeader(id)
      ) as HTMLInputElement;

      if (!dom) {
        continue;
      }

      if (dom.disabled) {
        continue;
      }
      logger.log(dom.outerHTML);

      dom.oninput = onInputHandler;
    }
  }
};

const fillAllFields = (fieldInputData: FieldInput[], paperColor: string) => {
  if (!fieldInputData?.length) {
    return;
  }

  fieldInputData.forEach((field, i) => {
    const dom = document.getElementById(
      createIDHeader(field.field_index)
    ) as HTMLInputElement;

    if (!dom) {
      return;
    }

    const fieldData = field.field_data;

    dom.disabled = true;
    dom.value = fieldData.raw_text;
    dom.style.fontFamily = fieldData.font;
    dom.style.color = fieldData.color;
    dom.style.backgroundColor = paperColor;
    dom.style.fontSize = field.is_signature ? '30px' : '12px';
    dom.style.fontStyle = field.is_signature ? 'italic' : 'normal';
    dom.style.fontWeight = 'bold';
  });
};

// Overarching component that holds the primary view for papercode.
export class PrimaryView extends Component {
  // Reference that gets passed to the <Section> holding the main preview.
  // Eventually gets filled with a reference to the section's scroll bar
  // funtionality.
  scrollableRef: RefObject<HTMLDivElement>;

  // The last recorded distance the scrollbar was from the bottom.
  // Used to implement "text scrolls up instead of down" behaviour.
  lastDistanceFromBottom: number;

  // Event handler for the onscroll event. Also gets passed to the <Section>
  // holding the main preview. Updates lastDistanceFromBottom.
  onScrollHandler: (this: GlobalEventHandlers, ev: Event) => any;

  constructor(props, context) {
    super(props, context);
    this.scrollableRef = createRef();
    this.lastDistanceFromBottom = 0;

    this.onScrollHandler = (ev: Event) => {
      const scrollable = ev.currentTarget as HTMLDivElement;
      if (scrollable) {
        this.lastDistanceFromBottom =
          scrollable.scrollHeight - scrollable.scrollTop;
      }
    };
  }

  render() {
    const { act, data } = useBackend<PaperContext>(this.context);
    const {
      default_pen_font,
      default_pen_color,
      paper_color,
      held_item_details,
    } = data;

    const useFont = held_item_details?.font || default_pen_font;
    const useColor = held_item_details?.color || default_pen_color;
    const useBold = held_item_details?.use_bold || false;

    const [textAreaText, setTextAreaText] = useLocalState(
      this.context,
      'textAreaText',
      ''
    );

    const [inputFieldData, setInputFieldData] = useLocalState(
      this.context,
      'inputFieldData',
      {}
    );

    const interactMode =
      held_item_details?.interaction_mode || InteractionType.reading;

    const savableData =
      textAreaText.length || Object.keys(inputFieldData).length;

    return (
      <>
        <PaperSheetStamper scrollableRef={this.scrollableRef} />
        <Flex direction="column" fillPositionedParent>
          <Flex.Item grow={3} basis={1}>
            <PreviewView
              scrollableRef={this.scrollableRef}
              handleOnScroll={this.onScrollHandler}
            />
          </Flex.Item>
          {interactMode === InteractionType.writing && (
            <Flex.Item shrink={1} height={TEXTAREA_INPUT_HEIGHT + 'px'}>
              <Section
                title="Insert Text"
                fitted
                fill
                buttons={
                  <Button.Confirm
                    disabled={!savableData}
                    content="Save"
                    color="good"
                    onClick={() => {
                      if (textAreaText.length) {
                        act('add_text', { text: textAreaText });
                        setTextAreaText('');
                      }
                      if (Object.keys(inputFieldData).length) {
                        act('fill_input_field', { field_data: inputFieldData });
                        setInputFieldData({});
                      }
                    }}
                  />
                }>
                <TextArea
                  scrollbar
                  noborder
                  value={textAreaText}
                  textColor={useColor}
                  fontFamily={useFont}
                  bold={useBold}
                  height={'100%'}
                  backgroundColor={paper_color}
                  onInput={(e, text) => {
                    setTextAreaText(text);
                    if (this.scrollableRef.current) {
                      let thisDistFromBottom =
                        this.scrollableRef.current.scrollHeight -
                        this.scrollableRef.current.scrollTop;
                      this.scrollableRef.current.scrollTop +=
                        thisDistFromBottom - this.lastDistanceFromBottom;
                    }
                  }}
                />
              </Section>
            </Flex.Item>
          )}
        </Flex>
      </>
    );
  }
}

export const PreviewView = (props, context) => {
  const { data } = useBackend<PaperContext>(context);
  const {
    raw_text_input,
    raw_field_input,
    default_pen_font,
    default_pen_color,
    paper_color,
    held_item_details,
    signature_font,
    user_name,
  } = data;

  const [textAreaText] = useLocalState(context, 'textAreaText', '');
  const [inputFieldData, setInputFieldData] = useLocalState(
    context,
    'inputFieldData',
    {}
  );

  const [sigFieldData, setSigFieldData] = useLocalState(
    context,
    'sigFieldData',
    {}
  );

  const parsedAndSanitisedHTML = createPreview(
    raw_text_input,
    raw_field_input,
    canEdit(held_item_details) ? textAreaText : null,
    default_pen_font,
    default_pen_color,
    paper_color,
    held_item_details
  );

  const onInputHandler = (ev) => {
    const input = ev.currentTarget as HTMLInputElement;
    if (input.value.length) {
      inputFieldData[getHeaderID(input.id)] = input.value;
    } else {
      delete inputFieldData[getHeaderID(input.id)];
    }
    setInputFieldData(inputFieldData);
    input.style.fontFamily = held_item_details?.font || default_pen_font;
    input.style.color = held_item_details?.color || default_pen_color;
  };

  if (canEdit(held_item_details)) {
    hookAllFields(parsedAndSanitisedHTML, onInputHandler);
  }

  const textHTML = {
    __html: '<span class="paper-text">' + parsedAndSanitisedHTML + '</span>',
  };

  const { scrollableRef, handleOnScroll } = props;

  return (
    <Section
      fill
      fitted
      scrollable
      scrollableRef={scrollableRef}
      onScroll={handleOnScroll}>
      <Box
        fillPositionedParent
        position="relative"
        bottom={'100%'}
        minHeight="100%"
        backgroundColor={paper_color}
        className="Paper__Page"
        dangerouslySetInnerHTML={textHTML}
        p="10px"
      />
      <StampView />
    </Section>
  );
};

export const StampView = (props, context) => {
  const { data } = useBackend<PaperContext>(context);

  const { raw_stamp_input = [] } = data;

  const { stampYOffset } = props;

  return (
    <>
      {raw_stamp_input.map((stamp, index) => {
        return (
          <Stamp
            key={index}
            x={stamp.x}
            y={stamp.y}
            rotation={stamp.rotation}
            sprite={stamp.class}
            yOffset={stampYOffset}
          />
        );
      })}
    </>
  );
};

export const PaperSheet = (props, context) => {
  const { data } = useBackend<PaperContext>(context);
  const { paper_color, paper_name, held_item_details } = data;

  const writeMode = canEdit(held_item_details);

  if (!writeMode) {
    const [inputFieldData, setInputFieldData] = useLocalState(
      context,
      'inputFieldData',
      {}
    );
    if (Object.keys(inputFieldData).length) {
      setInputFieldData({});
    }
  }

  return (
    <Window
      title={paper_name}
      theme="paper"
      width={420}
      height={500 + (writeMode ? TEXTAREA_INPUT_HEIGHT : 0)}>
      <Window.Content backgroundColor={paper_color}>
        <PrimaryView />
      </Window.Content>
    </Window>
  );
};
