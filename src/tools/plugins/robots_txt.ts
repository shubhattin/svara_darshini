import { writeFileSync } from 'fs';
import { resolve } from 'path';
import { SitemapStream, streamToPromise } from 'sitemap';
import { Readable } from 'stream';
import type { PluginOption } from 'vite';

const make_robots_txt = () => {
  const robotsTxt = `User-agent: *
User-agent: *
Disallow: /_app/
Disallow: /~partytown/
Disallow: /img/
Disallow: manifest.json

Sitemap: ${process.env.VITE_SITE_URL ?? ''}/sitemap.xml
`;

  writeFileSync(resolve('static/robots.txt'), robotsTxt);
};

const make_sitemap = async () => {
  const links = [{ url: '/', changefreq: 'weekly', priority: 1 }];
  const stream = new SitemapStream({
    hostname: process.env.VITE_SITE_URL ?? 'http://localhost:5173'
  });
  const data = await streamToPromise(Readable.from(links).pipe(stream)).then((data) =>
    data.toString()
  );
  writeFileSync('static/sitemap.xml', data);
};

export function generateRobotsTxt() {
  return {
    name: 'generate-robots-txt',
    async buildStart() {
      make_robots_txt();
      await make_sitemap();
    }
  } as PluginOption;
}
