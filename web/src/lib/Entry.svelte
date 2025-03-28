<script lang="ts">
	let { id } = $props();
</script>

<article>
	<h2>{title}</h2>
	<img src={img} alt={ img_desc }/>
	<p>{desc}</p>
	<a href={link}>Source</a>
</article>
