+++
draft = false
title = "Administration"
synopsis = "Datamesh (dm) is a flexible, clusterable data fabric that enables data portability in development."
knowledgelevel = ""
date = 2017-12-20T11:17:29Z
[menu]
  [menu.main]
    parent = "concepts"
+++

{{% overview %}}
1. A sound understanding of git flows
2. [Kubernetes](https://www.kubernetes.com) & [Docker](https://www.docker.com) installed in place xyz.
3. Patience and coffee
{{% /overview %}}

## Heading level two.
Therefore, I saw that here was a sort of interregnum in Providence; for its even-handed equity never could have so gross an injustice. And yet still further pondering—while I moved him now and then from between the whale and ship, which would threaten to jam him—still further pondering.

I say, I saw that this situation of mine was the precise situation of every mortal that breathes; only, in most cases, he, one way or other, $dm docker inlinecode block has this Siamese connexion with a plurality of other mortals. If your banker breaks, you snap; if your apothecary by mistake sends you poison in your pills, you die.

{{< figure src="http://www.fillmurray.com/1600/1200" title="Look it's Bill Murray everybody" >}}

Therefore, I saw that here was a sort of interregnum in Providence; for its even-handed equity never could have so gross an injustice. And yet still further pondering—while I moved him now and then from between the whale and ship, which would threaten to jam him—still further pondering.

I say, I saw that this situation of mine was the precise situation of every mortal that breathes; only, in most cases, he, one way or other, $dm docker inlinecode block has this Siamese connexion with a plurality of other mortals. If your banker breaks, you snap; if your apothecary by mistake sends you poison in your pills, you die.

#### Private Container Registries.
Therefore, I saw that here was a sort of interregnum in Providence; for its even-handed equity never could have so gross an injustice. And yet still further pondering—while I moved him now and then from between the whale and ship, which would threaten to jam him—still further pondering.

I say, I saw that this situation of mine was the precise situation of every mortal that breathes; only, in most cases, he, one way or other, $dm docker inlinecode block has this Siamese connexion with a plurality of other mortals. If your banker breaks, you snap; if your apothecary by mistake sends you poison in your pills, you die.

{{< youtube A8ScwhLh7uo >}}

Therefore, I saw that here was a sort of interregnum in Providence; for its even-handed equity never could have so gross an injustice. And yet still further pondering—while I moved him now and then from between the whale and ship, which would threaten to jam him—still further pondering.

I say, I saw that this situation of mine was the precise situation of every mortal that breathes; only, in most cases, he, one way or other, $dm docker inlinecode block has this Siamese connexion with a plurality of other mortals. If your banker breaks, you snap; if your apothecary by mistake sends you poison in your pills, you die.

## Specifying the Kubernetes version
Therefore, I saw that here was a sort of interregnum in Providence; for its even-handed equity never could have so gross an injustice. And yet still further pondering—while I moved him now and then from between the whale and ship, which would threaten to jam him—still further pondering.

```go
package main

import (
	"fmt"
	"os"
	"github.com/lukemarsden/datamesh/cmd/dm/pkg/commands"
	"github.com/opentracing/opentracing-go"
	zipkin "github.com/openzipkin/zipkin-go-opentracing"
)

func main() {
	// Set up enough opentracing infrastructure that spans will be injected into outgoing HTTP requests, even if we're not going to push spans into
	// zipkin ourselves
	collector := &zipkin.NopCollector{}
	tracer, err := zipkin.NewTracer(
		zipkin.NewRecorder(collector, false, "127.0.0.1:0", "datamesh-cli"),
		zipkin.ClientServerSameSpan(true),
		zipkin.TraceID128Bit(true),
	)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	opentracing.InitGlobalTracer(tracer)

	// Execute the command
	if err := commands.MainCmd.Execute(); err != nil {
		os.Exit(-1)
	}
}
```

## Heading two.
I say, I saw that this situation of mine was the precise situation of every mortal that breathes; only, in most cases, he, one way or other, $dm docker inlinecode block has this Siamese connexion with a plurality of other mortals. If your banker breaks, you snap; if your apothecary by mistake sends you poison in your pills, you die.

I say, I saw that this situation of mine was the precise situation of every mortal that breathes; only, in most cases, he, one way or other, $dm docker inlinecode block has this Siamese connexion with a plurality of other mortals. If your banker breaks, you snap; if your apothecary by mistake sends you poison in your pills, you die.

{{< vimeo 241758164 >}}


##### Persistent Volumes.
Therefore, I saw that here was a sort of interregnum in Providence; for its even-handed equity never could have so gross an injustice. And yet still further pondering—while I moved him now and then from between the whale and ship, which would threaten to jam him—still further pondering.

I say, I saw that this situation of mine was the precise situation of every mortal that breathes; only, in most cases, he, one way or other, $dm docker inlinecode block has this Siamese connexion with a plurality of other mortals. If your banker breaks, you snap; if your apothecary by mistake sends you poison in your pills, you die.
