export type GraphPoint = {
  yRatio: number;
  pitch: number;
  note: string;
  //   originalIndex: number;
  scale: number;
};

export type GraphRow = {
  y: number;
  noteName: string;
  sargamKey: string;
  noteColor: string;
  /** font boldness */
  highlightNote: boolean;
  /** font boldness */
  highlightSargam: boolean;
  drawGrid: boolean;
  /** opacity of the note, default is 1 */
  noteOpacity?: number;
  /** opacity of the sargam, default is 1 */
  sargamOpacity?: number;
};
