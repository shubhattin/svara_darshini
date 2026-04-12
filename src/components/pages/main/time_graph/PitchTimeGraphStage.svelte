<script lang="ts">
  import { Circle, Layer, Line, Rect, Shape, Stage, Text } from 'svelte-konva';
  import type { Context } from 'konva/lib/Context';
  import type { Shape as KonvaShape } from 'konva/lib/Shape';

  type GraphPoint = {
    yRatio: number;
    pitch: number;
    note: string;
    clarity: number;
    originalIndex: number;
    scale: number;
  };

  type GraphRow = {
    y: number;
    noteName?: string;
    sargamKey?: string;
    noteColor?: string;
    highlightNote: boolean;
    highlightSargam: boolean;
    drawGrid: boolean;
  };

  let {
    containerWidth,
    containerHeight,
    VIEWBOX_W,
    VIEWBOX_H,
    GRAPH_PADDING,
    GRAPH_WIDTH,
    GRAPH_HEIGHT,
    VISIBLE_POINTS,
    graphData,
    noteRows,
    noteGradientNotes,
    noteColors,
    graphPalette
  }: {
    containerWidth: number;
    containerHeight: number;
    VIEWBOX_W: number;
    VIEWBOX_H: number;
    GRAPH_PADDING: { top: number; left: number; right: number; bottom: number };
    GRAPH_WIDTH: number;
    GRAPH_HEIGHT: number;
    VISIBLE_POINTS: number;
    graphData: GraphPoint[];
    noteRows: GraphRow[];
    noteGradientNotes: string[];
    noteColors: Record<string, string>;
    graphPalette: {
      background: string;
      grid: string;
      axis: string;
      label: string;
      labelStrong: string;
      point: string;
    };
  } = $props();

  const getXPosOnGraph = (index: number) =>
    (index / Math.max(VISIBLE_POINTS - 1, 1)) * GRAPH_WIDTH + GRAPH_PADDING.left;
  const getYPosOnGraph = (yRatio: number) =>
    GRAPH_HEIGHT + GRAPH_PADDING.top - yRatio * GRAPH_HEIGHT;

  const createCurveControlPoints = (
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    smoothing = 0.3
  ) => {
    const dx = x2 - x1;
    return {
      controlPoint1X: x1 + dx * smoothing,
      controlPoint1Y: y1,
      controlPoint2X: x2 - dx * smoothing,
      controlPoint2Y: y2
    };
  };

  const buildGradient = (context: Context) => {
    const gradient = context.createLinearGradient(0, GRAPH_PADDING.top + GRAPH_HEIGHT, 0, GRAPH_PADDING.top);
    noteGradientNotes.forEach((note, index) => {
      gradient.addColorStop(index / Math.max(noteGradientNotes.length - 1, 1), noteColors[note]);
    });
    return gradient;
  };

  const drawJumpSegments = (context: Context, shape: KonvaShape) => {
    if (graphData.length < 2) return;

    const canvasContext = context._context;
    const gradient = buildGradient(context);
    canvasContext.save();
    canvasContext.beginPath();

    for (let index = 1; index < graphData.length; index++) {
      const prev = graphData[index - 1];
      const point = graphData[index];
      const prevX = getXPosOnGraph(index - 1);
      const prevY = getYPosOnGraph(prev.yRatio);
      const x = getXPosOnGraph(index);
      const y = getYPosOnGraph(point.yRatio);
      const deltaPitch = point.pitch - prev.pitch;
      const deltaY = y - prevY;
      const isJump = (deltaPitch > 0 && deltaY > 0) || (deltaPitch < 0 && deltaY < 0);
      if (!isJump) continue;

      const { controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y } =
        createCurveControlPoints(prevX, prevY, x, y);
      canvasContext.moveTo(prevX, prevY);
      canvasContext.bezierCurveTo(
        controlPoint1X,
        controlPoint1Y,
        controlPoint2X,
        controlPoint2Y,
        x,
        y
      );
    }

    canvasContext.globalAlpha = 0.3;
    canvasContext.strokeStyle = gradient;
    canvasContext.lineWidth = 2;
    canvasContext.lineJoin = 'round';
    canvasContext.lineCap = 'round';
    canvasContext.stroke();
    canvasContext.restore();
  };

  const drawMainSegments = (context: Context, _shape: KonvaShape) => {
    if (graphData.length === 0) return;

    const canvasContext = context._context;
    const gradient = buildGradient(context);
    canvasContext.save();
    canvasContext.beginPath();
    canvasContext.moveTo(getXPosOnGraph(0), getYPosOnGraph(graphData[0].yRatio));

    for (let index = 1; index < graphData.length; index++) {
      const prev = graphData[index - 1];
      const point = graphData[index];
      const prevX = getXPosOnGraph(index - 1);
      const prevY = getYPosOnGraph(prev.yRatio);
      const x = getXPosOnGraph(index);
      const y = getYPosOnGraph(point.yRatio);
      const deltaPitch = point.pitch - prev.pitch;
      const deltaY = y - prevY;
      const isJump = (deltaPitch > 0 && deltaY > 0) || (deltaPitch < 0 && deltaY < 0);

      if (isJump) {
        canvasContext.moveTo(x, y);
        continue;
      }

      const { controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y } =
        createCurveControlPoints(prevX, prevY, x, y);
      canvasContext.bezierCurveTo(
        controlPoint1X,
        controlPoint1Y,
        controlPoint2X,
        controlPoint2Y,
        x,
        y
      );
    }

    canvasContext.strokeStyle = gradient;
    canvasContext.lineWidth = 2;
    canvasContext.lineJoin = 'round';
    canvasContext.lineCap = 'round';
    canvasContext.stroke();
    canvasContext.restore();
  };

  const lastPoint = $derived(graphData[graphData.length - 1]);
  const lastX = $derived(lastPoint ? getXPosOnGraph(graphData.length - 1) : GRAPH_PADDING.left);
  const lastY = $derived(lastPoint ? getYPosOnGraph(lastPoint.yRatio) : GRAPH_PADDING.top);
  const isRightSide = $derived(lastX > VIEWBOX_W * 0.85);
  const isNearTop = $derived(lastY < GRAPH_PADDING.top + 20);
  const indicatorX = $derived(isRightSide ? lastX - 170 : lastX + 10);
  const indicatorY = $derived(isNearTop ? lastY + 14 : lastY - 14);
</script>

<div class="time-graph-stage h-full w-full">
  <Stage
    width={VIEWBOX_W}
    height={VIEWBOX_H}
    divWrapperProps={{
      class: 'h-full w-full',
      style: `width:${containerWidth}px;height:${containerHeight}px;`
    }}
  >
    <Layer>
      <Rect
        x={0}
        y={0}
        width={VIEWBOX_W}
        height={VIEWBOX_H}
        cornerRadius={8}
        fill={graphPalette.background}
        listening={false}
      />

      {#each noteRows as row}
        {#if row.drawGrid}
          <Line
            points={[GRAPH_PADDING.left, row.y, GRAPH_PADDING.left + GRAPH_WIDTH, row.y]}
            stroke={graphPalette.grid}
            strokeWidth={1}
            listening={false}
          />
        {/if}

        {#if row.noteColor}
          <Circle
            x={GRAPH_PADDING.left - 5}
            y={row.y}
            radius={2}
            fill={row.noteColor}
            listening={false}
          />
        {/if}

        {#if row.noteName}
          <Text
            x={GRAPH_PADDING.left - 34}
            y={row.y - 5}
            width={24}
            height={10}
            text={row.noteName}
            fill={row.highlightNote ? graphPalette.labelStrong : graphPalette.label}
            fontSize={10}
            fontStyle={row.highlightNote ? '600' : '500'}
            align="right"
            verticalAlign="middle"
            listening={false}
          />
        {/if}

        {#if row.sargamKey}
          <Text
            x={GRAPH_PADDING.left - 50}
            y={row.y - 5}
            width={16}
            height={10}
            text={row.sargamKey}
            fill={row.highlightSargam ? graphPalette.labelStrong : graphPalette.label}
            fontSize={10}
            fontStyle={row.highlightSargam ? '600' : '500'}
            fontFamily="ome_bhatkhande_en"
            align="right"
            verticalAlign="middle"
            listening={false}
          />
        {/if}
      {/each}

      <Line
        points={[
          GRAPH_PADDING.left,
          GRAPH_PADDING.top,
          GRAPH_PADDING.left,
          GRAPH_HEIGHT + GRAPH_PADDING.top
        ]}
        stroke={graphPalette.axis}
        strokeWidth={2}
        listening={false}
      />
      <Line
        points={[
          GRAPH_PADDING.left,
          GRAPH_HEIGHT + GRAPH_PADDING.top,
          GRAPH_WIDTH + GRAPH_PADDING.left,
          GRAPH_HEIGHT + GRAPH_PADDING.top
        ]}
        stroke={graphPalette.axis}
        strokeWidth={1}
        opacity={0.8}
        listening={false}
      />

      {#if graphData.length > 1}
        <Shape sceneFunc={drawJumpSegments} listening={false} />
        <Shape sceneFunc={drawMainSegments} listening={false} />
      {/if}

      {#if lastPoint}
        <Circle x={lastX} y={lastY} radius={4} fill={graphPalette.point} listening={false} />
        <Text
          x={indicatorX}
          y={indicatorY - 5}
          width={160}
          height={10}
          text={`${lastPoint.pitch.toFixed(1)} Hz (${lastPoint.note}${lastPoint.scale})`}
          fill={graphPalette.labelStrong}
          fontSize={10}
          fontStyle="500"
          align={isRightSide ? 'right' : 'left'}
          verticalAlign="middle"
          listening={false}
        />
      {/if}
    </Layer>
  </Stage>
</div>

<style>
  :global(.time-graph-stage > div) {
    width: 100% !important;
    height: 100% !important;
  }

  :global(.time-graph-stage .konvajs-content) {
    width: 100% !important;
    height: 100% !important;
  }

  :global(.time-graph-stage canvas) {
    width: 100% !important;
    height: 100% !important;
    display: block;
  }
</style>
