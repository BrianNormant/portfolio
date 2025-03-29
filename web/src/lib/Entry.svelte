<script lang="ts">
	let { id } = $props();

	let title :string = 'This website';
	let img :string = 'https://i.insider.com/4e0b8f4dccd1d54255060000?width=700&format=jpeg&auto=webp';
	let img_desc :string = 'a website';
	let desc :string = `
	This is a website
	`;
	let link :string = 'https://github.com/BrianNormant';
</script>

<article>
	<h2>{title}</h2>
	<img src={img} alt={ img_desc }/>
	<p>{desc}</p>
	<a href={link}>Source</a>
</article>
