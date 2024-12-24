import type { Config } from 'drizzle-kit';
import { get_db_url } from './src/db/db_utils';
import dotenv from 'dotenv';

dotenv.config({ path: './.env.local' });

export default {
  schema: './src/db/schema.ts',
  out: './src/db/migrations',
  driver: 'pg',
  dbCredentials: {
    connectionString: get_db_url(process.env)
  }
} satisfies Config;
