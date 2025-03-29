<script lang="ts">
  import Entry from './lib/Entry.svelte'
  let ids: number[] = []; // Array to store the IDs from the API
  let id :number = 0; // Placeholder
  let loading :boolean = true;
  let error: string | null = null;

    async function fetchIds() {
    try {
      const response = await fetch('portfolio.ggkbrian.com/api/all');

      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }

      const data = await response.json();

      if (!Array.isArray(data)) {
        throw new Error('API returned data is not an array.');
      }

      ids = data;
      loading = false;
    } catch (err) {
      error = err instanceof Error ? err.message : 'An unknown error occurred.';
      loading = false;
      console.error('Error fetching IDs:', err);
    }
  }

  fetchIds(); // Call the function to fetch IDs when the component mounts

</script>

<main>
  <h1>My Portfolio</h1>
  <section>
    <Entry {id}/>
  </section>
</main>

<style>
  h1 {
    text-align: center;
  }
</style>
