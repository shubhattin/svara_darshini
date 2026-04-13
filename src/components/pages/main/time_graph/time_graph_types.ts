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
  highlightNote: boolean;
  highlightSargam: boolean;
  drawGrid: boolean;
};
