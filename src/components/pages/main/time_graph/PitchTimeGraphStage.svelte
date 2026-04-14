<script lang="ts">
  import { Circle, Layer, Line, Path, Rect, Stage, Text } from 'svelte-konva';
  import type { GraphPoint, GraphRow } from './time_graph_types';

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
    reorderedNotes: noteGradientNotes,
    noteColors,
    graphPalette,
    show_jumps
  }: {
    containerWidth: number;
    containerHeight: number;
    VIEWBOX_W: number;
    VIEWBOX_H: number;
    GRAPH_PADDING: { top: number; left: number; right: number; bottom: number };
    GRAPH_WIDTH: number;
    GRAPH_HEIGHT: number;
    /** Number of points visible in the graph based on screen size */
    VISIBLE_POINTS: number;
    graphData: GraphPoint[];
    noteRows: GraphRow[];
    reorderedNotes: string[];
    noteColors: Record<string, string>;
    graphPalette: {
      background: string;
      grid: string;
      axis: string;
      label: string;
      labelStrong: string;
      point: string;
    };
    show_jumps: boolean;
  } = $props();

  const stageWidth = $derived(Math.max(1, containerWidth));
  const stageHeight = $derived(Math.max(1, containerHeight));
  /** Map logical VIEWBOX_* coordinates to stage pixels without CSS-stretching the canvas. */
  const layerScaleX = $derived(VIEWBOX_W > 0 ? stageWidth / VIEWBOX_W : 1);
  const layerScaleY = $derived(VIEWBOX_H > 0 ? stageHeight / VIEWBOX_H : 1);

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

  const gradientStops = $derived(
    noteGradientNotes.flatMap((note, index) => [
      index / Math.max(noteGradientNotes.length - 1, 1),
      noteColors[note]
    ])
  );

  const buildMainPathData = () => {
    if (graphData.length < 2) return '';

    const commands: string[] = [`M ${getXPosOnGraph(0)} ${getYPosOnGraph(graphData[0].yRatio)}`];

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
        commands.push(`M ${x} ${y}`);
        continue;
      }

      const { controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y } =
        createCurveControlPoints(prevX, prevY, x, y);
      commands.push(
        `C ${controlPoint1X} ${controlPoint1Y}, ${controlPoint2X} ${controlPoint2Y}, ${x} ${y}`
      );
    }

    return commands.join(' ');
  };

  const buildJumpPathData = () => {
    if (graphData.length < 2) return '';

    const commands: string[] = [];

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
      commands.push(
        `M ${prevX} ${prevY} C ${controlPoint1X} ${controlPoint1Y}, ${controlPoint2X} ${controlPoint2Y}, ${x} ${y}`
      );
    }

    return commands.join(' ');
  };

  const jumpPathData = $derived(buildJumpPathData());
  const mainPathData = $derived(buildMainPathData());

  const INDICATOR_LABEL_WIDTH = 160;
  const INDICATOR_MARGIN = 10;

  const lastPoint = $derived(graphData[graphData.length - 1]);
  const lastX = $derived(lastPoint ? getXPosOnGraph(graphData.length - 1) : GRAPH_PADDING.left);
  const lastY = $derived(lastPoint ? getYPosOnGraph(lastPoint.yRatio) : GRAPH_PADDING.top);
  const isRightSide = $derived(
    lastX + INDICATOR_MARGIN + INDICATOR_LABEL_WIDTH > VIEWBOX_W - GRAPH_PADDING.right
  );
  const isNearTop = $derived(lastY < GRAPH_PADDING.top + 20);
  const indicatorX = $derived(
    isRightSide ? lastX - INDICATOR_MARGIN - INDICATOR_LABEL_WIDTH : lastX + INDICATOR_MARGIN
  );
  const INDICATOR_TEXT_HEIGHT = 10;
  const rawIndicatorY = $derived(isNearTop ? lastY + 14 : lastY - 14);
  const indicatorY = $derived(
    Math.min(
      Math.max(rawIndicatorY, GRAPH_PADDING.top + INDICATOR_TEXT_HEIGHT / 2),
      VIEWBOX_H - GRAPH_PADDING.bottom - INDICATOR_TEXT_HEIGHT / 2
    )
  );
</script>

<div class="time-graph-stage h-full w-full">
  <Stage
    width={stageWidth}
    height={stageHeight}
    divWrapperProps={{
      class: 'h-full w-full'
    }}
  >
    <Layer scaleX={layerScaleX} scaleY={layerScaleY}>
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

        <!-- Color of the note -->
        <Circle
          x={GRAPH_PADDING.left - 5}
          y={row.y}
          radius={2}
          fill={row.noteColor}
          opacity={row.noteOpacity ?? 1}
          listening={false}
        />

        <!-- Note name -->
        <Text
          x={GRAPH_PADDING.left - 34}
          y={row.y - 5}
          width={24}
          height={10}
          text={row.noteName}
          fill={row.highlightNote ? graphPalette.labelStrong : graphPalette.label}
          fontSize={10}
          fontStyle="normal"
          align="right"
          verticalAlign="middle"
          opacity={row.noteOpacity ?? 1}
          listening={false}
        />

        <!-- Sargam key -->
        <Text
          x={GRAPH_PADDING.left - 45}
          y={row.y - 5 + 2}
          width={16}
          height={10}
          text={row.sargamKey}
          fill={row.highlightSargam ? graphPalette.labelStrong : graphPalette.label}
          fontSize={10}
          fontStyle="normal"
          fontFamily="ome_bhatkhande_en"
          align="right"
          verticalAlign="middle"
          opacity={row.sargamOpacity ?? 1}
          listening={false}
        />
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
        {#if show_jumps}
          <Path
            data={jumpPathData}
            stroke={graphPalette.label}
            strokeWidth={2}
            opacity={0.3}
            lineJoin="round"
            lineCap="round"
            strokeLinearGradientStartPointY={GRAPH_PADDING.top + GRAPH_HEIGHT}
            strokeLinearGradientEndPointY={GRAPH_PADDING.top}
            strokeLinearGradientColorStops={gradientStops}
            listening={false}
          />
        {/if}
        <Path
          data={mainPathData}
          stroke={graphPalette.label}
          strokeWidth={2}
          lineJoin="round"
          lineCap="round"
          strokeLinearGradientStartPointY={GRAPH_PADDING.top + GRAPH_HEIGHT}
          strokeLinearGradientEndPointY={GRAPH_PADDING.top}
          strokeLinearGradientColorStops={gradientStops}
          listening={false}
        />
      {/if}

      {#if lastPoint}
        <Circle x={lastX} y={lastY} radius={4} fill={graphPalette.point} listening={false} />
        <Text
          x={indicatorX}
          y={indicatorY - 5}
          width={INDICATOR_LABEL_WIDTH}
          height={10}
          text={`${lastPoint.pitch.toFixed(1)} Hz (${lastPoint.note}${lastPoint.scale})`}
          fill={graphPalette.labelStrong}
          fontSize={10}
          fontStyle="normal"
          align={isRightSide ? 'right' : 'left'}
          verticalAlign="middle"
          listening={false}
        />
      {/if}
    </Layer>
  </Stage>
</div>

<style>
  :global(.time-graph-stage canvas) {
    display: block;
  }
</style>
