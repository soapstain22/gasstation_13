/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { vecAdd, vecInverse, vecMultiply } from 'common/vector';
import { winget, winset } from './byond';
import { createLogger } from './logging';
import { storage } from 'common/storage';

const logger = createLogger('drag');

const windowId = window.__windowId__;
let windowKey = windowId;
let dragging = false;
let resizing = false;
let screenOffset = [0, 0];
let screenOffsetPromise;
let dragPointOffset;
let resizeMatrix;
let initialSize;
let size;

export const setWindowKey = key => {
  windowKey = key;
};

export const getWindowPosition = id => [
  window.screenLeft,
  window.screenTop,
];

export const setWindowPosition = (id, vec) => {
  const byondPos = vecAdd(vec, screenOffset);
  return winset(id, 'pos', byondPos[0] + ',' + byondPos[1]);
};

export const getWindowSize = id => [
  window.innerWidth,
  window.innerHeight,
];

export const setWindowSize = (id, vec) => {
  return winset(id, 'size', vec[0] + ',' + vec[1]);
};

export const storeWindowGeometry = key => {
  logger.log('storing geometry');
  const geometry = {
    pos: getWindowPosition(),
    size: getWindowSize(),
  };
  storage.set(key, geometry);
};

export const recallWindowGeometry = async (key, defaults = {}) => {
  const geometry = storage.get(key);
  if (geometry) {
    logger.log('recalled geometry:', geometry);
  }
  const pos = geometry?.pos || defaults.pos;
  if (pos) {
    await screenOffsetPromise;
    setWindowPosition(windowId, pos);
  }
  const size = defaults.size;
  if (size) {
    setWindowSize(windowId, size);
  }
};

export const setupDrag = async state => {
  logger.log('setting up');
  // Calculate offset caused by windows taskbar
  screenOffsetPromise = winget(windowId, 'pos')
    .then(pos => [
      pos.x - window.screenLeft,
      pos.y - window.screenTop,
    ]);
  screenOffset = await screenOffsetPromise;
  // Constraint window position
  const [relocated, safePosition] = constraintPosition(getWindowPosition());
  if (relocated) {
    setWindowPosition(windowId, safePosition);
  }
  logger.debug('current state', { windowId, screenOffset });
};

/**
 * Constraints window position to safe screen area, accounting for safe
 * margins which could be a system taskbar.
 */
const constraintPosition = position => {
  let x = position[0];
  let y = position[1];
  let relocated = false;
  // Left
  if (x < 0) {
    x = 0;
    relocated = true;
  }
  // Right
  else if (x + window.innerWidth > window.screen.availWidth) {
    x = window.screen.availWidth - window.innerWidth;
    relocated = true;
  }
  // Top
  if (y < 0) {
    y = 0;
    relocated = true;
  }
  // Bottom
  else if (y + window.innerHeight > window.screen.availHeight) {
    y = window.screen.availHeight - window.innerHeight;
    relocated = true;
  }
  return [relocated, [x, y]];
};

export const dragStartHandler = event => {
  logger.log('drag start');
  dragging = true;
  dragPointOffset = [
    window.screenLeft - event.screenX,
    window.screenTop - event.screenY,
  ];
  document.addEventListener('mousemove', dragMoveHandler);
  document.addEventListener('mouseup', dragEndHandler);
  dragMoveHandler(event);
};

const dragEndHandler = event => {
  logger.log('drag end');
  dragMoveHandler(event);
  document.removeEventListener('mousemove', dragMoveHandler);
  document.removeEventListener('mouseup', dragEndHandler);
  dragging = false;
  storeWindowGeometry(windowKey);
};

const dragMoveHandler = event => {
  if (!dragging) {
    return;
  }
  event.preventDefault();
  setWindowPosition(windowId, vecAdd(
    [event.screenX, event.screenY],
    dragPointOffset));
};

export const resizeStartHandler = (x, y) => event => {
  resizeMatrix = [x, y];
  logger.log('resize start', resizeMatrix);
  resizing = true;
  dragPointOffset = [
    window.screenLeft - event.screenX,
    window.screenTop - event.screenY,
  ];
  initialSize = [
    window.innerWidth,
    window.innerHeight,
  ];
  document.addEventListener('mousemove', resizeMoveHandler);
  document.addEventListener('mouseup', resizeEndHandler);
  resizeMoveHandler(event);
};

const resizeEndHandler = event => {
  logger.log('resize end', size);
  resizeMoveHandler(event);
  document.removeEventListener('mousemove', resizeMoveHandler);
  document.removeEventListener('mouseup', resizeEndHandler);
  resizing = false;
  storeWindowGeometry(windowKey);
};

const resizeMoveHandler = event => {
  if (!resizing) {
    return;
  }
  event.preventDefault();
  size = vecAdd(initialSize, vecMultiply(resizeMatrix, vecAdd(
    [event.screenX, event.screenY],
    vecInverse([window.screenLeft, window.screenTop]),
    dragPointOffset,
    [1, 1])));
  // Sane window size values
  size[0] = Math.max(size[0], 250);
  size[1] = Math.max(size[1], 120);
  setWindowSize(windowId, size);
};
