<script lang="ts">
  import { PatreonIcon, PayPalIcon, RazorpayIcon, UPIIcon, YoutubeIcon } from '~/components/icons';
  import Icon from '~/tools/Icon.svelte';
  import QRCode from 'qrcode';
  import { onMount } from 'svelte';

  const UPI_ID = 'thesanskritchannel@okicici';
  const UPI_ID_LINK = `upi://pay?pa=${UPI_ID}&pn=The%20Sanskrit%20Channel&cu=INR`;
  let qr_canvas: HTMLCanvasElement | null = $state(null);
  let darkColor = '#000000';
  let lightColor = '#ffffff';
  const CANVAS_SIZE = $state(145);

  onMount(() => {
    QRCode.toCanvas(qr_canvas!, UPI_ID_LINK, {
      width: CANVAS_SIZE,
      margin: 1,
      color: {
        dark: darkColor,
        light: lightColor
      }
    });
  });
</script>

<div>
  <div class="text-center text-lg font-bold text-amber-700 dark:text-warning-500">
    <div>Support Our Projects</div>
    <div class="text-sm">Pay as you wish</div>
  </div>
  <div class="mt-2.5">
    <!-- <div class="text-center text-lg font-bold">One Time Contributions:</div> -->

    <div class="flex text-center text-sm">
      <Icon src={UPIIcon} class="-mt-1.5 text-3xl" /> UPI :
      <a
        href={UPI_ID_LINK}
        target="_blank"
        class="ml-1 select-none text-blue-600 outline-none hover:text-blue-500 dark:text-blue-400 dark:hover:text-blue-300"
        rel="noopener noreferrer">{UPI_ID}</a
      >
    </div>
    <div class="flex justify-center">
      <canvas
        bind:this={qr_canvas}
        class="block h-auto w-full"
        height={CANVAS_SIZE}
        width={CANVAS_SIZE}
      ></canvas>
    </div>
    <div class="mt-2 flex justify-center space-x-3">
      <a
        href="https://www.paypal.me/thesanskritchannel"
        target="_blank"
        rel="noopener noreferrer"
        class="inline-block"
        title="Support us on Paypal"
      >
        <Icon src={PayPalIcon} class="-mt-3 text-4xl" />
      </a>
      <a
        href="https://pages.razorpay.com/thesanskritchannel"
        target="_blank"
        rel="noopener noreferrer"
        class="inline"
        title="Support us on Razorpay"
      >
        <Icon src={RazorpayIcon} class="-my-12 -mt-3 text-8xl" />
      </a>
    </div>
    <div class="mt-3 flex justify-center space-x-5">
      <a
        href="https://www.patreon.com/thesanskritchannel"
        target="_blank"
        class="pt-1 dark:bg-white"
        title="Support us on Patreon"
      >
        <Icon src={PatreonIcon} class="-mt-1 text-4xl" />
      </a>
      <a
        href="https://www.youtube.com/channel/UCqFg6QnwgtVHo1iFgpxrx-A/join"
        target="_blank"
        title="Support us on Youtube"
      >
        <Icon src={YoutubeIcon} class="mt-0 text-4xl text-[red]" />
      </a>
    </div>
  </div>
</div>
